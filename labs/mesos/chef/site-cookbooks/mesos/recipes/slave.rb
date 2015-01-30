# Mesos-slave specific configuration
#

# Overriging default variables
node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['masters'] = ENV['mesos_masters'].to_s.empty? ? node['mesos']['masters'] :  ENV['mesos_masters']

# Include common stuff
include_recipe 'mesos::common'

# Override mesos network interface if in vagrant env
vagrant=`grep "vagrant" /etc/passwd >/dev/null && echo "yes" || echo "no"`
if vagrant == "yes"
    node.override['mesos']['slave']['interface'] = 'eth1'
end

# Manage hostname and it's resolution
hostname = node['mesos']['slave']['hostname']
ip_address = IPFinder.find_by_interface(node, "#{node['mesos']['slave']['interface']}", :private_ipv4)

execute "hostname #{hostname}" do
  only_if { node['hostname'] != hostname }
  notifies :reload, 'ohai[reload_hostname]', :immediately
end

file '/etc/hostname' do
  content "#{hostname}\n"
  mode '0644'
  notifies :reload, 'ohai[reload_hostname]', :immediately
end

# If we are on ec2 set the public dns as the hostname so that
# mesos slave reports work properly in the UI.
if node.attribute?('ec2') && node['mesos']['set_ec2_hostname']
  bash 'set-aws-public-hostname' do
    user 'root'
    code <<-EOH
      PUBLIC_DNS=`wget -q -O - http://instance-data.ec2.internal/latest/meta-data/public-hostname`
      hostname $PUBLIC_DNS
      echo $PUBLIC_DNS > /etc/hostname
      HOSTNAME=$PUBLIC_DNS  # Fix the bash built-in hostname variable too
    EOH
    not_if 'hostname | grep amazonaws.com'
  end
  notifies :reload, 'ohai[reload_hostname]', :immediately
end

ohai 'reload_hostname' do
  plugin 'hostname'
  action :reload
end

hostname = node['mesos']['master']['hostname']

hostsfile_entry "#{ip_address}" do
  hostname "#{hostname}"
  action :append
end

# Insert new local dns nameserver in the top of resolv.conf
File.open('/etc/resolv.conf.new', 'w') do |fo|
  File.open('/etc/resolv.conf') do |fi|
    if not fi.read.include? "nameserver #{node['mesos']['masters'].to_s.split(',').sample}"
      fo.puts "nameserver #{node['mesos']['masters'].to_s.split(',').sample}"
    end
  end
  File.foreach('/etc/resolv.conf') do |li|
    fo.puts li
  end
end

File.rename('/etc/resolv.conf', '/etc/resolv.conf.old')
File.rename('/etc/resolv.conf.new', '/etc/resolv.conf')

# Include slave common stuff
include_recipe 'mesos::slave-common'
