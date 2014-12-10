# Dealing with Zookeeper
#

# Overriding default attributes
node.override['build-essential']['compile_time'] = true
node.override['java']['jdk_version'] = '7'
node.override['zookeeper']['version'] = ENV['zk_version'].to_s.empty? ? node[:zookeeper][:version] : ENV['zk_version']

# Forming path's and uri's
executable_path = ::File.join(node[:zookeeper][:install_dir],
                              "zookeeper-#{node[:zookeeper][:version]}",
                              'bin',
                              'zkServer.sh')

zookeeper_uri = ::File.join(node[:zookeeper][:mirror],
                              "zookeeper-#{node[:zookeeper][:version]}",
                              "zookeeper-#{node[:zookeeper][:version]}.tar.gz")

config_path = ::File.join(node[:zookeeper][:install_dir],
                          "zookeeper-#{node[:zookeeper][:version]}",
                          'conf',
                          'zoo.cfg')

node.override['zookeeper']['checksum'] = `curl -kL #{zookeeper_uri}.md5 2>/dev/null | awk '{print $1}'`

# Get zookeeper servers either from ENV or from chef environment provided by knife
# Must be in a form of comma-separated list
node.override['zookeeper']['servers'] = ENV['zk_servers'].to_s.empty? ? node[:zookeeper][:servers] : ENV['zk_servers']

# Java and runit are provided by corresponding cookbooks
include_recipe 'build-essential::default'
include_recipe 'java::default'
include_recipe 'runit'

# IPFinder depends on this gem
chef_gem "ipaddr_extensions" do
  version '1.0.0'
end

# Getting zookeeper tarball and extracting it to install_dir
zookeeper node[:zookeeper][:version] do
  user        node[:zookeeper][:user]
  mirror      node[:zookeeper][:mirror]
  checksum    node[:zookeeper][:checksum]
  install_dir node[:zookeeper][:install_dir]
  action      :install
end

# Crafting a config
template "#{config_path}" do
  source "zoo.cfg.erb"
  user node[:zookeeper][:user]
  mode "0755"
  variables({
    :zk_servers => node[:zookeeper][:servers]
  })
end

# Creating data_dir
directory node[:zookeeper][:data_dir] do
  owner node[:zookeeper][:user]
end

# Configuring myid
template "#{node[:zookeeper][:data_dir]}/myid" do
  source "myid.erb"
  owner node[:zookeeper][:user]
  variables({
    :zk_servers => node[:zookeeper][:servers]
  })
  not_if { node[:zookeeper][:servers].nil? }
end

# Adding zookeeper to init
runit_service 'zookeeper' do
  default_logger true
  options({
    exec: executable_path
  })
  action [:enable, :start]
end

# Subscribe to config changes
service 'zookeeper' do
  subscribes :restart, resources(:template => "#{config_path}")
end
