# IPFinder depends on this gem
chef_gem "ipaddr_extensions" do
  version '1.0.0'
end

# Override network interface if in vagrant env
vagrant=`grep "vagrant" /etc/passwd >/dev/null && echo -n "yes" || echo -n "no"`
if vagrant == "yes"
    node.override['kafka']['interface'] = 'eth1'
end

# Hostname resolution for Java in VPC
ip_address = IPFinder.find_by_interface(node, "#{node['kafka']['interface']}", :private_ipv4)

hostsfile_entry "#{ip_address}" do
  hostname  node[:hostname]
  action    :append
end