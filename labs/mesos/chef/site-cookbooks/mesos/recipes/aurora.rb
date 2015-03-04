# Recipe for Aurora framework
#

# Override default attributes
node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node[:mesos][:zk_servers] : ENV['zk_servers']
node.override['mesos']['masters'] = ENV['mesos_masters'].to_s.empty? ? node[:mesos][:masters] :  ENV['mesos_masters']

if not ENV['aurora_url'].to_s.empty?
  node.override['mesos']['aurora']['tarball_url'] = ENV['aurora_url']
end

directory node[:mesos][:aurora][:install_dir] do
  owner "root"
  group "root"
  recursive true
end

remote_file "#{node[:mesos][:aurora][:install_dir]}/aurora.tar" do
  action :create_if_missing
  source node[:mesos][:aurora][:tarball_url]
  not_if { ::File.directory?("#{node[:mesos][:aurora][:install_dir]}/bin") }
end

execute "extract aurora" do
  command "tar -xvf aurora.tar --strip=1"
  cwd node[:mesos][:aurora][:install_dir]
  creates "#{node[:mesos][:aurora][:install_dir]}/bin"
end

file "#{node[:mesos][:aurora][:install_dir]}/aurora.tar" do
  action :delete
end

# Initializing log
execute "initialize log" do
  command "mesos-log initialize --path=#{node[:mesos][:aurora][:install_dir]}/db"
  not_if { ::File.directory?("#{node[:mesos][:aurora][:install_dir]}/db")}
end

# Configure mesos with zookeeper server(s)
template "#{node[:mesos][:aurora][:install_dir]}/aurora-scheduler.sh" do
  source 'aurora/aurora-scheduler.sh.erb'
  mode 0755
  variables(
    :zk_servers => node[:mesos][:zk_servers].to_s.empty? ? node[:mesos][:masters] : node[:mesos][:zk_servers],
    :zookeeper_port => node[:mesos][:zookeeper_port],
    :mesos_masters => node[:mesos][:masters],
    :aurora_home => node[:mesos][:aurora][:install_dir]
  )
  notifies :restart, "service[aurora-scheduler]", :delayed
end

# Add aurora to init
runit_service 'aurora-scheduler' do
    default_logger true
    options({
        :install_dir => "#{node[:mesos][:aurora][:install_dir]}"
    })
    action [:enable, :start]
end