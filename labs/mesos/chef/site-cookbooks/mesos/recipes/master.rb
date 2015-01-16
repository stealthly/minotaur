# Mesos-master specific configuration
#

# Overriging default variables
node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node[:mesos][:zk_servers] : ENV['zk_servers']
node.override['mesos']['masters'] = ENV['mesos_masters'].to_s.empty? ? node[:mesos][:masters] :  ENV['mesos_masters']

# Override mesos network interface if in vagrant env
vagrant=`grep "vagrant" /etc/passwd >/dev/null && echo -n "yes" || echo -n "no"`
if vagrant == "yes"
    node.override['mesos']['master']['interface'] = 'eth1'
end

# Include common stuff
include_recipe 'mesos::common'

# Manage hostname and it's resolution
hostname = node[:mesos][:master][:hostname]
ip_address = IPFinder.find_by_interface(node, "#{node[:mesos][:master][:interface]}", :private_ipv4)

execute "hostname #{hostname}" do
  only_if { node['hostname'] != hostname }
  notifies :reload, 'ohai[reload_hostname]', :immediately
end

file '/etc/hostname' do
  content "#{hostname}\n"
  mode '0644'
  notifies :reload, 'ohai[reload_hostname]', :immediately
end

ohai 'reload_hostname' do
  plugin 'hostname'
  action :reload
end

hostsfile_entry "#{ip_address}" do
  hostname "#{hostname}"
  action :append
end

# Include node-specific stuff
include_recipe 'mesos::zookeeper'
if 'marathon' in ENV['modules']
  include_recipe 'mesos::marathon'
end
if 'aurora' in ENV['modules']
  include_recipe 'mesos::aurora'
end

# Configure mesos with zookeeper server(s)
template '/etc/mesos/zk' do
  source 'zk.erb'
  variables(
    :zk_servers => node[:mesos][:zk_servers].to_s.empty? ? node[:mesos][:masters] : node[:mesos][:zk_servers],
    :zookeeper_port => node[:mesos][:zookeeper_port],
    :zookeeper_path => node[:mesos][:zookeeper_path]
  )
  notifies :restart, "service[mesos-master]", :delayed
end

# Manage master-specific configs
template '/etc/default/mesos' do
  source 'mesos.erb'
  variables(
    :log_dir => node[:mesos][:log_dir],
  )
  notifies :restart, "service[mesos-master]", :delayed
end

template '/etc/default/mesos-master' do
  source 'master/mesos-master.erb'
  variables(
    :port => node[:mesos][:port],
    :cluster_name => node[:mesos][:cluster_name],
  )
  notifies :restart, "service[mesos-master]", :delayed
end

# Returning master to autostart
template '/etc/init/mesos-master.conf' do
  source 'master/mesos-master.conf.erb'
  variables(
    action: 'start',
  )
end

if node[:platform] == 'ubuntu'
  service 'mesos-master' do
    action [:start, :enable]
    provider Chef::Provider::Service::Upstart
  end
else
  service 'mesos-master' do
    action [:start, :enable]
    provider Chef::Provider::Service::Init::Redhat
  end
end