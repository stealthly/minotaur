include_recipe 'kafka_broker::hostsfile'
include_recipe 'java::default'
include_recipe 'runit'

# Get zk_servers and kafka brokers either from ENV or from chef environment provided by knife
# Must be in a form of comma-separated list
node.override['kafka']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node[:kafka][:zk_servers] : ENV['zk_servers']
node.override['kafka']['brokers'] = ENV['kafka_brokers'].to_s.empty? ? node[:kafka][:brokers] : ENV['kafka_brokers']

# Override versions and url attributes if tarball url provided
if not ENV['kafka_url'].to_s.empty?
  node.override['kafka']['tarball_url'] = ENV['kafka_url']
  node.override['kafka']['tarball_base'] = "kafka"
  node.override['kafka']['tarball_name'] = "#{node[:kafka][:tarball_base]}.tar.gz"
end

# If no zk_servers configured - install and use local zookeeper
if node[:kafka][:zk_servers].to_s.empty?
  include_recipe 'runit::default'
  include_recipe 'zookeeper::default'
  include_recipe 'zookeeper::service'
end

group node[:kafka][:group] do
end

user node[:kafka][:user] do
  comment "Kafka user"
  gid node[:kafka][:group]
  shell "/bin/noshell"
  supports :manage_home => false
end

directory node[:kafka][:install_dir] do
  owner node[:kafka][:user]
  group node[:kafka][:group]
  recursive true
end

directory node[:kafka][:log_dir] do
  owner "root"
  group "root"
  recursive true
end

remote_file "#{node[:kafka][:install_dir]}/#{node[:kafka][:tarball_name]}" do
  action :create_if_missing
  source node[:kafka][:tarball_url]
  not_if { ::File.directory?("#{node[:kafka][:install_dir]}/bin") }
end

execute 'extract kafka source' do
  command "tar -zxvf #{node[:kafka][:tarball_name]} --strip=1"
  cwd node[:kafka][:install_dir]
  creates "#{node[:kafka][:install_dir]}/bin"
end

file "#{node[:kafka][:install_dir]}/#{node[:kafka][:tarball_name]}" do
    action :delete
end

%w[server.properties].each do |template_file|
  template "#{node[:kafka][:install_dir]}/config/#{template_file}" do
    source  "#{template_file}.erb"
    owner node[:kafka][:user]
    group node[:kafka][:group]
    mode  00755
    variables({
      :kafka => node[:kafka],
      :zk_servers => node[:kafka][:zk_servers],
      :kafka_brokers => node[:kafka][:brokers]
    })
  end
end

template "#{node[:kafka][:install_dir]}/bin/service-control.sh" do
  source  "service-control.erb"
  owner "root"
  group "root"
  mode  00755
  variables({
    :install_dir => node[:kafka][:install_dir],
    :log_dir => node[:kafka][:log_dir],
    :java_home => node[:java][:java_home],
    :java_jmx_port => node[:kafka][:jmx_port],
    :java_class => "kafka.Kafka",
    :user => node[:kafka][:user]
  })
end

# Adding kafka to init
runit_service "kafka" do
  options({
    :install_dir => node[:kafka][:install_dir],
    :log_dir => node[:kafka][:log_dir],
    :java_home => node[:java][:java_home],
    :user => node[:kafka][:user]
  })
end
