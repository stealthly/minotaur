# Mesos-slave specific configuration
#

# Overriging default variables
node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['masters'] = ENV['mesos_masters'].to_s.empty? ? node['mesos']['masters'] :  ENV['mesos_masters']
node.override['mesos']['masters_eip'] = ENV['mesos_masters_eip'].to_s.empty? ? node['mesos']['masters_eip'] :  ENV['mesos_masters_eip']
node.override['route53']['zone_name'] = ENV['hosted_zone_name'].to_s.empty? ? node['route53']['zone_name'] :  ENV['hosted_zone_name']

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

remote_file "/usr/local/bin/haproxy-marathon-bridge" do
  source node[:mesos][:marathon][:haproxy_bridge_url]
  action :create
  mode '0755'
  not_if { ::File.exist? '/usr/local/bin/haproxy-marathon-bridge' }
end

# Restart rsyslog to enable haproxy logging
service 'rsyslog' do
  action [:restart]
end

# If we are on ec2 set the public dns as the hostname so that
# mesos slave reports work properly in the UI.
if node.attribute?('ec2') && node['mesos']['set_ec2_hostname']
  bash 'set-aws-public-hostname' do
    user 'root'
    code <<-EOH
      PUBLIC_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`
      hostname $PUBLIC_DNS
      echo $PUBLIC_DNS > /etc/hostname
      HOSTNAME=$PUBLIC_DNS  # Fix the bash built-in hostname variable too
    EOH
    not_if 'hostname | grep ec2.internal'
    notifies :reload, 'ohai[reload_hostname]', :immediately
  end
else
  execute "hostname #{hostname}" do
    only_if { node['hostname'] != hostname }
    notifies :reload, 'ohai[reload_hostname]', :immediately
  end
  file '/etc/hostname' do
    content "#{hostname}\n"
    mode '0644'
    notifies :reload, 'ohai[reload_hostname]', :immediately
  end
end

ohai 'reload_hostname' do
  plugin 'hostname'
  action :reload
end

hostsfile_entry "#{ip_address}" do
  hostname node['fqdn'] || node['machinename']
  action :append
end

# Include slave common stuff
include_recipe 'mesos::slave-common'

# Template route53 dns entry json payload
template '/tmp/route53_record.json' do
  source 'mesos-dns/route53_record.json.erb'
  variables(
    name: "slave-#{ip_address.gsub('.', '-')}.#{node['route53']['zone_name']}",
    value: "#{node['mesos']['masters_eip'].split(',').sample}"
  )
end

# Run haproxy-marathon-bridge script
bash 'haproxy-marathon-bridge' do
  user 'root'
  code "haproxy-marathon-bridge install_haproxy_system #{node['mesos']['masters'].to_s.split(',').sample}:8080"
  not_if 'ls /etc/haproxy-marathon-bridge | grep marathons'
end
