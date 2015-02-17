# Recipe for mesos-dns
#

# Install mesos-dns binary
directory node[:mesos][:dns][:install_dir] do
  owner "root"
  group "root"
  recursive true
end

remote_file "#{node[:mesos][:dns][:install_dir]}/mesos-dns" do
  action :create_if_missing
  source node[:mesos][:dns][:bin_url]
  mode '0755'
end

# Configure mesos dns service
template "#{node[:mesos][:dns][:install_dir]}/config.json" do
  source 'mesos-dns/config.json.erb'
  variables(
    :masters => node[:mesos][:masters],
    :mesos_port => "5050"
  )
end
