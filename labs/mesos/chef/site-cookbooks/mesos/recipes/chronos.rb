# Recipe for Chronos framework
#

case node[:platform]
when 'ubuntu'
  apt_package "chronos" do
    action :install
  end
when 'rhel', 'centos', 'amazon'
  yum_package "chronos" do
    action :install
  end
end

# Template gauntlet(validate.sh) task payload for chronos
template '/tmp/gauntlet.json' do
source 'gauntlet/gauntlet.json.erb'
variables(
  gauntlet_install_dir: node['mesos']['gauntlet']['install_dir'],
)
end

service 'chronos' do
  action [ :enable, :start ]
  subscribes :restart, "service[mesos-master]", :delayed
end
