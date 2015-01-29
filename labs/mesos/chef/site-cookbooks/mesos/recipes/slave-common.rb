# Mesos-slave common configuration
#

# Configure mesos with zookeeper server(s)
template '/etc/mesos/zk' do
  source 'zk.erb'
  variables(
    :zk_servers => node[:mesos][:zk_servers],
    :zookeeper_port => node[:mesos][:zookeeper_port],
    :zookeeper_path => node[:mesos][:zookeeper_path]
  )
  notifies :restart, "service[mesos-slave]", :delayed
end

# Manage slave-specific configs
template '/etc/default/mesos' do
  source 'mesos.erb'
  variables(
    :log_dir => node[:mesos][:log_dir],
    :isolation_type => node[:mesos][:slave][:isolation_type]
  )
  notifies :restart, "service[mesos-slave]", :delayed
end

template '/etc/default/mesos-slave' do
  source 'slave/mesos-slave.erb'
  variables(
    :port => node[:mesos][:port],
    :cluster_name => node[:mesos][:cluster_name],
    :work_dir => node[:mesos][:work_dir],
    :isolation_type => node[:mesos][:slave][:isolation_type]
  )
  notifies :restart, "service[mesos-slave]", :delayed
end

if ENV['mesos_version'] >= '0.21.0'
  env_sh_dir = '/usr/local/etc/mesos/mesos-slave-env.sh.template'
else
  env_sh_dir = '/usr/local/var/mesos/deploy/mesos-slave-env.sh.template'
end

template env_sh_dir do
  source 'slave/mesos-slave-env.sh.template.erb'
  variables(
    :zk_servers => node[:mesos][:zk_server],
    :zookeeper_port => node[:mesos][:zookeeper_port],
    :zookeeper_path => node[:mesos][:zookeeper_path],
    :log_dir => node[:mesos][:log_dir],
    :work_dir => node[:mesos][:work_dir],
    :isolation_type => node[:mesos][:slave][:isolation_type],
  )
  notifies :restart, "service[mesos-slave]", :delayed
end

# Set init to 'start' by default for mesos slave.
# This ensures that mesos-slave is started on restart
template '/etc/init/mesos-slave.conf' do
  source 'slave/mesos-slave.conf.erb'
  variables(
    action: 'start',
  )
end

directory '/etc/mesos-slave' do
  owner 'root'
  mode 0755
end

slave_ip_address = IPFinder.find_by_interface(node, "#{node['mesos']['slave']['interface']}", :private_ipv4)

node.override[:mesos][:slave][:attributes][:ip] = slave_ip_address

node[:mesos][:slave][:attributes].each do |opt, arg|
  file "/etc/mesos-slave/#{opt}" do
    content arg
    mode 0644
    action :create
    notifies :restart, "service[mesos-slave]", :delayed
  end
end

if node[:platform] == 'ubuntu'
  service 'mesos-slave' do
    action [:start, :enable]
    provider Chef::Provider::Service::Upstart
  end
else
  service 'mesos-slave' do
    action [:start, :enable]
    provider Chef::Provider::Service::Init::Redhat
  end
end
