# This recipe handles Active and Standby namenodes deployment
#
require 'net/ssh'

# Include pre-requisites 
include_recipe 'cdh::common'

# Znodes info container
zdata = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

# Figure our namenode role (active or secondary) and id

node.set['hadoop']['namenodes']['ips'] = ENV['namenodes'].to_s.split(',')
node.set['hadoop']['journalnodes']['ips'] = ENV['journalnodes'].to_s.split(',')
node.set['hadoop']['datanodes']['ips'] = ENV['datanodes'].to_s.split(',')
node.set['hadoop']['resourcemanagers']['ips'] = ENV['resourcemanagers'].to_s.split(',')
node.set['hadoop']['myip'] = IPFinder.find_by_interface(node, "#{node['hadoop']['namenodes']['interface']}", :private_ipv4)
node.set['hadoop']['myid'] = node['hadoop']['namenodes']['ips'].include?(node['hadoop']['myip']) ? node['hadoop']['namenodes']['ips'].index(node['hadoop']['myip']) : 0

# Create parent znodes
z = cdh_znode '/chef/hadoop/namenodes' do
  action :nothing
end

z.run_action(:create)

z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}" do
  action :nothing
end

z.run_action(:create)

z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}/ip" do
  action :nothing
end

z.run_action(:create)

# Put myip to corresponding znode
z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}/ip" do
  action :nothing
  content "#{node['hadoop']['myip']}"
end

z.run_action(:set)

#----------------
# Set hostname
hostname = "#{node['hadoop']['namenodes']['dns']['basename']}-#{node['hadoop']['myid']}.#{node['hadoop']['dns']['clustername']}"

execute "hostname #{hostname}" do
  only_if { node['hostname'] != hostname }
end

file '/etc/hostname' do
  content "#{hostname}\n"
  mode '0644'
  notifies :reload, 'ohai[reload_hostname]', :immediately
end

ohai 'reload_hostname' do
  plugin 'hostname'
  action :nothing
end

#---------------------------
# Build hdfs-site.xml config
node.set['hadoop']['hdfs_site']['dfs.nameservices'] = "#{node['hadoop']['dns']['clustername']}"
node.set['hadoop']['hdfs_site']['fs.defaultFS'] = "hdfs://#{node['hadoop']['hdfs_site']['dfs.nameservices']}"
node.set['hadoop']['hdfs_site']['dfs.ha.automatic-failover.enabled'] = "true"

# fencing
node.set['hadoop']['hdfs_site']['dfs.ha.fencing.methods'] = 'sshfence'
node.set['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir'] = '/var/lib/hadoop-hdfs/.ssh'
node.set['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.private-key-files'] = "#{node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir']}/id_rsa"

#
nnodes_list = []
node['hadoop']['namenodes']['ips'].each_with_index do |ip,index|
  nn_hostname = "#{node['hadoop']['namenodes']['dns']['basename']}-#{index}"
  nn_fqdn = "#{nn_hostname}.#{node['hadoop']['dns']['clustername']}"
  nnodes_list << nn_hostname
  node.set['hadoop']['hdfs_site']["dfs.namenode.rpc-address.#{node['hadoop']['dns']['clustername']}.#{nn_hostname}"] = "#{nn_fqdn}:8020"
  node.set['hadoop']['hdfs_site']["dfs.namenode.http-address.#{node['hadoop']['dns']['clustername']}.#{nn_hostname}"] = "#{nn_fqdn}:50070"

  # /etc/hosts entry
  hostsfile_entry "#{ip}" do
    hostname "#{nn_fqdn}"
    action :append
  end
end
node.set['hadoop']['hdfs_site']["dfs.ha.namenodes.#{node['hadoop']['dns']['clustername']}"] = "#{nnodes_list.join(',')}"

# datanodes 
dnodes_list = []
node['hadoop']['datanodes']['ips'].each_with_index do |ip,index|
  dn_hostname = "#{node['hadoop']['datanodes']['dns']['basename']}-#{index}"
  dn_fqdn = "#{dn_hostname}.#{node['hadoop']['dns']['clustername']}"
  dnodes_list << dn_hostname

  # /etc/hosts entry
  hostsfile_entry "#{ip}" do
    hostname "#{dn_fqdn}"
    action :append
  end
end

# shared journal
jnodes_list = []
node['hadoop']['journalnodes']['ips'].each_with_index do |ip,index|
  jn_fqdn = "#{node['hadoop']['journalnodes']['dns']['basename']}-#{index}.#{node['hadoop']['dns']['clustername']}"
  jnodes_list << "#{jn_fqdn}:8485"

  # /etc/hosts entry
  hostsfile_entry "#{ip}" do
    hostname "#{jn_fqdn}"
    action :append
  end
end
node.set['hadoop']['hdfs_site']['dfs.namenode.shared.edits.dir'] = "qjournal://#{jnodes_list.join(';')}/#{node['hadoop']['dns']['clustername']}"

#---------------------------
# Build core-site.xml config
# zookeepers
zks_list = []
node['hadoop']['zk_servers']['ips'].each_with_index do |ip,index|
  zk_fqdn = "#{node['hadoop']['zookeepers']['dns']['basename']}-#{index}.#{node['hadoop']['dns']['clustername']}"
  zks_list << "#{zk_fqdn}:2181"

  # /etc/hosts entry
  hostsfile_entry "#{ip}" do
    hostname "#{zk_fqdn}"
    action :append
  end
end
node.set['hadoop']['core_site']['ha.zookeeper.quorum'] = "#{zks_list.join(',')}"


#-------------------------------
# Include wrapped Hadoop recipes
include_recipe 'hadoop::hadoop_hdfs_namenode'
include_recipe 'hadoop::hadoop_hdfs_zkfc'

#------------------------------------------
# Generate SSH keypair and put pubkey to zk
# then gather other namenodes pubkeys
directory node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir'] do
  owner 'hdfs'
  group 'hadoop'
  mode 0700
end

unless (::File.exist? "#{node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir']}/id_rsa") then
  # Create znodes for SSH keys exchange
  z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}/ssh" do
    action :nothing
  end

  z.run_action(:create)

  z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}/ssh/pubkey" do
    action :nothing
  end

  z.run_action(:create)

  # Generate keypair (net/ssh fix must be included)
  private_key = OpenSSL::PKey::RSA.new 2048
  public_key = "#{private_key.ssh_type} #{[ private_key.to_blob ].pack('m0')}"

  # Save generated keypair
  file "#{node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir']}/id_rsa" do
    content "#{private_key}"
    owner 'hdfs'
    group 'hadoop'
    mode 0600
  end

  file "#{node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir']}/id_rsa.pub" do
    content "#{public_key}"
    owner 'hdfs'
    group 'hadoop'
    mode 0600
  end

  # Push pubkey to zookeeper
  z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}/ssh/pubkey" do
    action :nothing
    content "#{public_key}"
  end

  z.run_action(:set)
  # Set SSH status to ready
  z = cdh_znode "/chef/hadoop/namenodes/#{node['hadoop']['myid']}/ssh" do
    action :nothing
    content "ready"
  end

  z.run_action(:set)
  # Try to obtain other namenode's pubkey and
  # append it to authorized_keys
  node['hadoop']['namenodes']['ips'].each_with_index do |nn,index|
    # Wait till namenodes SSH keys are ready
    z = cdh_znode "/chef/hadoop/namenodes/#{index}/ssh" do
      action :nothing
      content "ready"
      retries 20
      retry_delay 10
    end

    z.run_action(:expect)

    z = cdh_znode "/chef/hadoop/namenodes/#{index}/ssh/pubkey" do
      action :nothing
      destination zdata['hadoop']['namenodes']["#{index}"]['ssh']['pubkey']
    end

    z.run_action(:get)

    # Add pubkey to authorized_keys
    insert_if_no_match "#{node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir']}/authorized_keys" do
      data zdata['hadoop']['namenodes']["#{index}"]['ssh']['pubkey']['content']
      owner 'hdfs'
      group 'hadoop'
      mode '0600'
    end

    # And IP to known_hosts
    fingerprint = `ssh-keyscan #{nn} 2>/dev/null | grep rsa | head -1`
    insert_if_no_match "#{node['hadoop']['hdfs_site']['dfs.ha.fencing.ssh.dir']}/known_hosts" do
      data "#{fingerprint}"
      owner 'hdfs'
      group 'hadoop'
      mode '0600'
    end

  end

end

#---------------------------------------------
# Format namenodes if journalnodes are ready
node['hadoop']['journalnodes']['ips'].each_with_index do |jn,index|
  cdh_znode "/chef/hadoop/journalnodes/#{index}/status" do
    action :expect
    content "ready"
    retries 60
    retry_delay 10
  end
end

#--------------------------
# Format zookeeper for zkfc
if node['hadoop']['myid'] == 0 # Namenode with 0 id will do it
  execute 'echo -e "Y\nY" | hdfs zkfc -formatZK' do
    user 'hdfs'
    group 'hadoop'
  end
end

#----------------------------------------
# Format hdfs (required on both namenodes)
execute 'echo -e "N" | hdfs namenode -format' do
  user 'hdfs'
  group 'hadoop'
  only_if { node['hadoop']['myid'] == 0 }
end

#-----------------------------
# Bootstrap standby namenode
execute 'echo -e "N" | hdfs namenode -bootstrapStandby' do
  user 'hdfs'
  group 'hadoop'
  retries 10 # standbyBootstrap will only succeed if active namenode is running
  not_if { node['hadoop']['myid'] == 0 }
end 

#--------------------
# Start zkfc failover
service 'hadoop-hdfs-zkfc' do
  action [ :enable, :start ]
end

#-----------------------
# Start namenode service
service 'hadoop-hdfs-namenode' do
  action [ :enable, :start ]
end
