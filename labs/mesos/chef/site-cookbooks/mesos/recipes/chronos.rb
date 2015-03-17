# Recipe for Chronos framework
#

# Override default attributes
node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node[:mesos][:zk_servers] : ENV['zk_servers']
node.override['mesos']['masters'] = ENV['mesos_masters'].to_s.empty? ? node[:mesos][:masters] :  ENV['mesos_masters']

directory node[:mesos][:chronos][:install_dir] do
  owner "root"
  group "root"
  recursive true
end

directory "#{node[:mesos][:chronos][:install_dir]}/environment" do
  owner "root"
  group "root"
  recursive true
end

directory node[:mesos][:chronos][:log_dir] do
  owner "root"
  group "root"
  recursive true
end

remote_file "#{node[:mesos][:chronos][:install_dir]}/chronos.tgz" do
  action :create_if_missing
  source node[:mesos][:chronos][:tarball_url]
  not_if { ::File.directory?("#{node[:mesos][:chronos][:install_dir]}/bin") }
end

execute "extract chronos" do
  command "tar -xzvf chronos.tgz --strip=1"
  cwd node[:mesos][:chronos][:install_dir]
  creates "#{node[:mesos][:chronos][:install_dir]}/bin"
end

file "#{node[:mesos][:chronos][:install_dir]}/chronos.tgz" do
  action :delete
end

# Template gauntlet(validate.sh) task payload for chronos
template '/tmp/gauntlet.json' do
  source 'chronos/gauntlet.json.erb'
  variables(
    gauntlet_install_dir: node['mesos']['gauntlet']['install_dir'],
    time: `date -Is --date 'now + 30 mins'`.strip,
    master_ip: node['mesos']['masters'].split(',').sample
)
end

runit_service 'chronos' do
  default_logger true
  options({
    :mesos_home => "/usr/local/lib",
    :extra_opts => "--mesos_task_cpu 1.0 --mesos_task_mem 1024 --mesos_task_disk 1024 \
--master zk://#{node['mesos']['zk_servers'].split(',').join(':2181,')}:2181/mesos \
--zk_hosts zk://#{node['mesos']['zk_servers'].split(',').join(':2181,')}:2181/mesos \
--http_port #{node['mesos']['chronos']['port']}"}.merge(params)
  )
  action [:enable, :start]
end

