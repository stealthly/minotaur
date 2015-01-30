# Recipe for mesos-dns
#

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

# Configure mesos dns marathon config
template "/tmp/mesos-dns.json" do
  source 'mesos-dns/mesos-dns.json.erb'
  variables(
    :slave => node[:mesos][:slave][:attributes][:ip]
  )
end

# Insert new local dns nameserver in the top of resolv.conf
ruby_block "insert_line" do
  block do
    file = Chef::Util::FileEdit.new("/etc/resolvconf/resolv.conf.d/head")
    file.insert_line_if_no_match("/nameserver 127.0.0.1/", "nameserver 127.0.0.1")
    file.write_file
  end
end
