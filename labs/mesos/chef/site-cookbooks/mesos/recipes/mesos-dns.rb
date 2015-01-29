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
end

# Insert new local dns nameserver in the top of resolv.conf
File.open('/etc/resolv.conf.new', 'w') do |fo|
  fo.puts 'nameserver 127.0.0.1'
  File.foreach('/etc/resolv.conf') do |li|
    fo.puts li
  end
end

File.rename('/etc/resolv.conf', '/etc/resolv.conf.old')
File.rename('/etc/resolv.conf.new', '/etc/resolv.conf')
