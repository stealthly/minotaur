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

# Install nokogiri with dependencies for route53 cookbook
if node[:platform] == 'ubuntu'
  apt_package "zlib1g-dev" do
    action :nothing
  end.run_action(:install)
end
node.set['build_essential']['compiletime'] = true
include_recipe "build-essential"

case node[:platform]
when 'ubuntu'
  apt_package 'libxml2-dev' do
    action :nothing
  end.run_action(:install)
  apt_package 'libxslt-dev' do
    action :nothing
  end.run_action(:install)
when 'rhel', 'centos', 'amazon'
  yum_package 'libxml2-devel' do
    action :nothing
  end.run_action(:install)
  yum_package 'libxslt-devel' do
    action :nothing
  end.run_action(:install)

chef_gem "nokogiri" do
  action :install
  version node['route53']['nokogiri_version']
end
chef_gem "fog" do
  action :install
  version node['route53']['fog_version']
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

# Platform-specific installation of packages
# from mesosphere
case node[:platform]
when 'ubuntu'
  if ENV['mesos_version'] >= '0.21.0'
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

  if ENV['mesos_version'] >= '0.21.0'
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

# Template haproxy-marathone-bridge script
template '/usr/local/bin/haproxy-marathon-bridge' do
  source 'mesos-dns/haproxy-marathon-bridge.erb'
  variables(
    mesos_master: "#{node['mesos']['masters'].split(',').sample}",
  )
  mode '0755'
end

# Edit rsyslog.conf to enable haproxy logging
ruby_block "insert_line" do
  block do
    file = Chef::Util::FileEdit.new("/etc/rsyslog.conf")
    file.insert_line_if_no_match("/$ModLoad imudp/", "$ModLoad imudp")
    file.insert_line_if_no_match("/$UDPServerAddress 127.0.0.1/", "$UDPServerAddress 127.0.0.1")
    file.insert_line_if_no_match("/$UDPServerRun 514/", "$UDPServerRun 514")
    file.write_file
  end
end
