# Manage zookeeper(s) on master node(s)
#

# Crafting config_path
config_path = ::File.join(node[:zookeeper][:install_dir],
                          "zookeeper-#{node[:zookeeper][:version]}",
                          'conf',
                          'zoo.cfg')

ip_address = Chef::IPFinder.find_by_interface(node, "#{node[:mesos][:master][:interface]}", :private_ipv4)

# If no external zookeeper nodes provided
if node[:mesos][:zk_servers].to_s.empty?
  # Deploy default zookeeper installation
  include_recipe 'zookeeper::default'
  include_recipe 'zookeeper::service'
  # ... and reconfigure zk if Mesos is in HA mode
  if node[:mesos][:masters].to_s.split(',').length > 1
    # Crafting a config
    template "#{config_path}" do
      source "zookeeper/zoo.cfg.erb"
      mode "0755"
      variables({
        :zk_servers => node[:mesos][:masters],
        :ip_address => "#{ip_address}"
      })
    end

    # Configuring myid
    template "#{node[:zookeeper][:data_dir]}/myid" do
      source "zookeeper/myid.erb"
      owner node[:zookeeper][:user]
      variables({
        :zk_servers => node[:mesos][:masters],
        :ip_address => "#{ip_address}"
      })
    end

    # Subscribe to config changes
    service 'zookeeper' do
      subscribes :restart, resources(:template => "#{config_path}")
    end
  end
end