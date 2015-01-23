# Common packages and configuration for mesos nodes
#

# Overriding default attributes
node.override['mesos']['version'] = ENV['mesos_version'].to_s.empty? ? node[:mesos][:version] : ENV['mesos_version']

# Forming path's and uri's
mesos_uri = ::File.join(node[:mesos][:mirror],
                                "master",
                                node[:platform],
                                node[:platform_version],
                                "mesos_#{node[:mesos][:version]}-#{node[:mesos][:subversion]}")

# Java, apt and yum are provided by corresponding community cookbooks
include_recipe 'apt'
include_recipe 'java::default'
include_recipe 'runit::default'

# Install IPAddr extensions gem
chef_gem "ipaddr_extensions" do
  version '1.0.0'
end

# Create working directory
directory node[:mesos][:work_dir] do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Mounting volume
if node.block_device.has_key?('xvdc')
  include_recipe 'mesos::mount-volume'
end

# Plarform-specific installation of packages
# from mesosphere
case node[:platform]
when 'ubuntu'
  if ENV['mesos_version'] == '0.21.0'
    apt_package "libapr1"
    apt_package "libsvn1"
  end

  remote_file "#{Chef::Config[:file_cache_path]}/mesos.deb" do
    source "#{mesos_uri}.ubuntu1404_amd64.deb"
    action :create
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end

  # Install mesos from deb package
  dpkg_package 'mesos' do
    source "#{Chef::Config[:file_cache_path]}/mesos.deb"
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end
when 'rhel', 'centos', 'amazon'
  # Amazon Linux has jdk 6 installed by default
  yum_package 'jdk' do
    action :purge
  end

  if ENV['mesos_version'] == '0.21.0'
    yum_package "libapr1"
    yum_package "libsvn1"
  end

  execute 'update java alternatives' do
    command '/usr/sbin/alternatives --auto java'
    action :run
  end

  execute 'ldconfig' do
    command '/sbin/ldconfig'
    action :nothing
  end

  file '/etc/ld.so.conf.d/jre.conf' do
    content "#{node['java']['java_home']}/jre/lib/amd64/server"
    notifies :run, 'execute[ldconfig]', :immediately
    mode 0644
  end

  remote_file "#{Chef::Config[:file_cache_path]}/mesos.rpm" do
    source "#{mesos_uri}.centos64.x86_64.rpm"
    action :create
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end

  rpm_package 'mesos' do
    source "#{Chef::Config[:file_cache_path]}/mesos.rpm"
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end
end

# Set init to 'stop' by default for mesos master.
# Running mesos::master recipe will reset this to 'start'
template '/etc/init/mesos-master.conf' do
  source 'master/mesos-master.conf.erb'
  variables(
    action: 'stop',
  )
end

# Set init to 'stop' by default for mesos slave.
# Running mesos::slave recipe will reset this to 'start'
template '/etc/init/mesos-slave.conf' do
  source 'slave/mesos-slave.conf.erb'
  variables(
    action: 'stop',
  )
end

# Remove mesos-master and slave from autostart
if node[:platform] == 'ubuntu'
  service 'mesos-slave' do
    action [:stop, :disable]
    provider Chef::Provider::Service::Upstart
  end
else
  service 'mesos-slave' do
    action [:stop, :disable]
    provider Chef::Provider::Service::Init::Redhat
  end
end
