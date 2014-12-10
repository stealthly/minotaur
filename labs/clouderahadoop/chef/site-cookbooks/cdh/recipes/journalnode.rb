# This recipe handles journalnodes deployment
#
# Include pre-requisites 
include_recipe 'cdh::common'

# Overriding attributes
node.override['hadoop']['journalnodes']['ips'] = ENV['journalnodes'].to_s.split(',')
node.override['hadoop']['myip'] = IPFinder.find_by_interface(node, "#{node['hadoop']['journalnodes']['interface']}", :private_ipv4)
node.override['hadoop']['myid'] = node['hadoop']['journalnodes']['ips'].include?(node['hadoop']['myip']) ? node['hadoop']['journalnodes']['ips'].index(node['hadoop']['myip']) : 0

# Creating parent znodes
znode '/chef/hadoop/journalnodes'
znode "/chef/hadoop/journalnodes/#{node[:hadoop][:myid]}"
znode "/chef/hadoop/journalnodes/#{node[:hadoop][:myid]}/status"

#----------------
# Set hostname
hostname = "#{node['hadoop']['journalnodes']['dns']['basename']}-#{node['hadoop']['myid']}.#{node['hadoop']['dns']['clustername']}"

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

# Shared edits directory
node.set['hadoop']['hdfs_site']['dfs.journalnode.edits.dir'] = "/tmp/jedits"

directory "#{node['hadoop']['hdfs_site']['dfs.journalnode.edits.dir']}" do
  action :create
  owner 'hdfs'
  group 'hadoop'
end

#----------------------------
# Including wrapped cookbooks
include_recipe 'hadoop::hadoop_hdfs_journalnode'


# Starting journalnode
service 'hadoop-hdfs-journalnode' do
  action [ :start, :enable ]
end

#-----------------------------
# Updating correspongind znode
# with 'ready' status

znode "/chef/hadoop/journalnodes/#{node[:hadoop][:myid]}/status" do
  action :set
  content 'ready'
end
