# Mesos-master specific configuration
#

# Overriging default variables
node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['masters'] = ENV['mesos_masters'].to_s.empty? ? node['mesos']['masters'] :  ENV['mesos_masters']
node.override['mesos']['masters_eip'] = ENV['mesos_masters_eip'].to_s.empty? ? node['mesos']['masters_eip'] :  ENV['mesos_masters_eip']
node.override['route53']['zone_name'] = ENV['hosted_zone_name'].to_s.empty? ? node['route53']['zone_name'] :  ENV['hosted_zone_name']

# Override mesos network interface if in vagrant env
vagrant=`grep "vagrant" /etc/passwd >/dev/null && echo -n "yes" || echo -n "no"`
if vagrant == "yes"
    node.override['mesos']['master']['interface'] = 'eth1'
end

# Include common stuff
include_recipe 'mesos::common'

# Include slave common stuff if in slave_on_master mode
if ENV['slave_on_master'] == 'true'
  include_recipe 'mesos::slave-common'
end

# Manage hostname and it's resolution
hostname = node['mesos']['master']['hostname']
ip_address = IPFinder.find_by_interface(node, "#{node['mesos']['master']['interface']}", :private_ipv4)

# Template haproxy-marathone-bridge script
template '/usr/local/bin/haproxy-marathon-bridge' do
  source 'mesos-dns/haproxy-marathon-bridge.erb'
  variables(
    mesos_master: "#{ip_address}",
  )
  mode '0755'
end

# If we are on ec2 set the public dns as the hostname so that
# mesos master redirection works properly.
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

# Include node-specific stuff
include_recipe 'mesos::zookeeper'
if ENV['marathon'] == 'true'
  include_recipe 'mesos::marathon'
end
if ENV['mesos_dns'] == 'true'
  # Configure mesos dns marathon config
  template "/tmp/mesos-dns.json" do
    source 'mesos-dns/mesos-dns.json.erb'
    variables(
      :install_dir => node[:mesos][:dns][:install_dir]
    )
  end
  include_recipe 'mesos::mesos-dns-common'
end
if ENV['aurora'] == 'true'
  include_recipe 'mesos::aurora'
end
if ENV['spark'] == 'true'
  include_recipe 'mesos::spark'
end
if ENV['gauntlet'] == 'true'
  include_recipe 'mesos::gauntlet'
end

# Configure mesos with zookeeper server(s)
template '/etc/mesos/zk' do
  source 'zk.erb'
  variables(
    :zk_servers => node[:mesos][:zk_servers].to_s.empty? ? node[:mesos][:masters] : node[:mesos][:zk_servers],
    :zookeeper_port => node[:mesos][:zookeeper_port],
    :zookeeper_path => node[:mesos][:zookeeper_path]
  )
  notifies :restart, "service[mesos-master]", :delayed
end

# Manage master-specific configs
template '/etc/default/mesos' do
  source 'mesos.erb'
  variables(
    :log_dir => node[:mesos][:log_dir],
  )
  notifies :restart, "service[mesos-master]", :delayed
end

template '/etc/default/mesos-master' do
  source 'master/mesos-master.erb'
  variables(
    :port => node[:mesos][:port],
    :cluster_name => node[:mesos][:cluster_name],
  )
  notifies :restart, "service[mesos-master]", :delayed
end

node.override[:mesos][:master][:attributes][:ip] = ip_address
node.override[:mesos][:master][:attributes][:hostname] = ip_address

node[:mesos][:master][:attributes].each do |opt, arg|
  file "/etc/mesos-master/#{opt}" do
    content arg
    mode 0644
    action :create
    notifies :restart, "service[mesos-master]", :delayed
  end
end

# Returning master to autostart
template '/etc/init/mesos-master.conf' do
  source 'master/mesos-master.conf.erb'
  variables(
    action: 'start',
  )
end

if node[:platform] == 'ubuntu'
  service 'mesos-master' do
    action [:start, :enable]
    provider Chef::Provider::Service::Upstart
  end
else
  service 'mesos-master' do
    action [:start, :enable]
    provider Chef::Provider::Service::Init::Redhat
  end
end

# Template route53 dns entry json payload
template '/tmp/route53_record.json' do
  source 'mesos-dns/route53_record.json.erb'
  variables(
    name: "master#{node['mesos']['masters'].split(',').index(ip_address)}.#{node['route53']['zone_name']}",
    value: "#{node['mesos']['masters_eip']}"
  )
end

# Run haproxy-marathon-bridge script
bash 'haproxy-marathon-bridge' do
  user 'root'
  code 'haproxy-marathon-bridge install_haproxy_system 127.0.0.1:8080'
  retries 5
  retry_delay 10
  not_if 'ls /etc/haproxy-marathon-bridge | grep marathons'
end

# Restart rsyslog to enable haproxy logging
service 'rsyslog' do
  action [:nothing]
  subscribes :restart, "bash[haproxy-marathon-bridge]", :immediately
end
