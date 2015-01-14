# This recipe handles datanodes deployment
#
# Include pre-requisites 
include_recipe 'cdh::common'

# Figure our datanode's id
node.set['hadoop']['namenodes']['ips'] = ENV['namenodes'].to_s.split(',')
node.set['hadoop']['datanodes']['ips'] = ENV['datanodes'].to_s.split(',')
node.set['hadoop']['resourcemanagers']['ips'] = ENV['resourcemanagers'].to_s.split(',')
node.set['hadoop']['myip'] = IPFinder.find_by_interface(node, "#{node['hadoop']['datanodes']['interface']}", :private_ipv4)
node.set['hadoop']['myid'] = node['hadoop']['datanodes']['ips'].include?(node['hadoop']['myip']) ? node['hadoop']['datanodes']['ips'].index(node['hadoop']['myip']) : 0

# Create parent znodes
cdh_znode '/chef/hadoop/datanodes'
cdh_znode "/chef/hadoop/datanodes/#{node['hadoop']['myid']}"
cdh_znode "/chef/hadoop/datanodes/#{node['hadoop']['myid']}/ip"

# Put myip to corresponding znode
cdh_znode "/chef/hadoop/datanodes/#{node['hadoop']['myid']}/ip" do
  action :set
  content "#{node['hadoop']['myip']}"
end

#----------------
# Set hostname
hostname = "#{node['hadoop']['datanodes']['dns']['basename']}-#{node['hadoop']['myid']}.#{node['hadoop']['dns']['clustername']}"

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

# namenodes
nns_list = []
node['hadoop']['namenodes']['ips'].each_with_index do |ip,index|
  nn_hostname = "#{node['hadoop']['namenodes']['dns']['basename']}-#{index}"
  nn_fqdn = "#{nn_hostname}.#{node['hadoop']['dns']['clustername']}"
  nns_list << nn_hostname
  node.set['hadoop']['hdfs_site']["dfs.namenode.rpc-address.#{node['hadoop']['dns']['clustername']}.#{nn_hostname}"] = "#{nn_fqdn}:8020"
  node.set['hadoop']['hdfs_site']["dfs.namenode.http-address.#{node['hadoop']['dns']['clustername']}.#{nn_hostname}"] = "#{nn_fqdn}:50070"

  # /etc/hosts entry
  hostsfile_entry "#{ip}" do
    hostname "#{nn_fqdn}"
    action :append
  end
end
node.set['hadoop']['hdfs_site']["dfs.ha.namenodes.#{node['hadoop']['dns']['clustername']}"] = "#{nns_list.join(',')}"

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

#---------------------------
# Build hdfs-site.xml config
node.set['hadoop']['hdfs_site']['dfs.nameservices'] = "#{node['hadoop']['dns']['clustername']}"
node.set['hadoop']['hdfs_site']['fs.defaultFS'] = "hdfs://#{node['hadoop']['hdfs_site']['dfs.nameservices']}"

#---------------------------
# Nodemanager-related stuff
#---------------------------
yarn_hostname = "#{node['hadoop']['resourcemanagers']['dns']['basename']}-0.#{node['hadoop']['dns']['clustername']}" 

node.set['hadoop']['yarn_site']['yarn.resourcemanager.hostname'] = "#{yarn_hostname}"
node.set['hadoop']['yarn_site']['yarn.resourcemanager.address'] = "#{yarn_hostname}:8032"
node.set['hadoop']['yarn_site']['yarn.resourcemanager.scheduler.address'] = "#{yarn_hostname}:8030"
node.set['hadoop']['yarn_site']['yarn.resourcemanager.webapp.address'] = "#{yarn_hostname}:8088"
node.set['hadoop']['yarn_site']['yarn.resourcemanager.resource-tracker.address'] = "#{yarn_hostname}:8031"
node.set['hadoop']['yarn_site']['yarn.resourcemanager.admin.address'] = "#{yarn_hostname}:8033"

# resourcemanagers
rmanagers_list = []
node['hadoop']['resourcemanagers']['ips'].each_with_index do |ip,index|
  rm_fqdn = "#{node['hadoop']['resourcemanagers']['dns']['basename']}-#{index}.#{node['hadoop']['dns']['clustername']}"
  rmanagers_list << "#{rm_fqdn}:8485"

  # /etc/hosts entry
  hostsfile_entry "#{ip}" do
    hostname "#{rm_fqdn}"
    action :append
  end
end

#-------------------------------
# Include wrapped Hadoop recipes
include_recipe 'hadoop::hadoop_hdfs_datanode'
include_recipe 'hadoop::hadoop_yarn_nodemanager'

#-----------------------
# Start datanode service
service 'hadoop-hdfs-datanode' do
  action [ :enable, :restart ]
end

# and nodemanager
service 'hadoop-yarn-nodemanager' do
  action [ :enable, :restart ]
end
