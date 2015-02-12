# Recipe for Marathon framework
#

# Overriding default attributes
node.override['mesos']['marathon']['version'] = ENV['marathon_version'].to_s.empty? ? node[:mesos][:marathon][:version] : ENV['marathon_version']


# Forming path's and uri's
marathon_uri = ::File.join(node[:mesos][:mirror],
                                "marathon",
                                "v#{node[:mesos][:marathon][:version]}",
                                "marathon_#{node[:mesos][:marathon][:version]}-#{node[:mesos][:marathon][:subversion]}")

case node[:platform]
when 'ubuntu'
  remote_file "#{Chef::Config[:file_cache_path]}/marathon.deb" do
    source "#{marathon_uri}_amd64.deb"
    action :create
    not_if { ::File.exist? '/usr/local/bin/marathon' }
  end

  # Install mesos from deb package
  dpkg_package 'marathon' do
    source "#{Chef::Config[:file_cache_path]}/marathon.deb"
    not_if { ::File.exist? '/usr/local/bin/marathon' }
  end
when 'rhel', 'centos', 'amazon'
  remote_file "#{Chef::Config[:file_cache_path]}/marathon.rpm" do
    source "#{marathon_uri}.x86_64.rpm"
    action :create
    not_if { ::File.exist? '/usr/local/bin/marathon' }
  end

  rpm_package 'marathon' do
    source "#{Chef::Config[:file_cache_path]}/marathon.rpm"
    not_if { ::File.exist? '/usr/local/bin/marathon' }
  end
end

# Set configuration with environmental attributes
node[:mesos][:marathon][:attributes].each do |opt, arg|
  ENV["MARATHON_#{opt.upcase}"] = arg
end

service 'marathon' do
  action [ :enable, :start ]
end
