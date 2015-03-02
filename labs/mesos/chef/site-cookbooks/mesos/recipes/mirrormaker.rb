# Install mirrormaker
#

node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['kafka_servers'] = ENV['kafka_servers'].to_s.empty? ? node['mesos']['kafka_servers'] : ENV['kafka_servers']

remote_file "/usr/local/bin/mirror_maker" do
  action :create_if_missing
  source node[:mesos][:mirrormaker][:bin_url]
end

template "#{node['mesos']['gauntlet']['install_dir']}/mirrormaker/consumer.config" do
  source 'mirrormaker/consumer.config.erb'
  variables(
    zk_servers: node['mesos']['zk_servers'].split(',').sample,
  )
end

template '/tmp/producer.config' do
  source 'mirrormaker/producer.config.erb'
  variables(
    kafka_servers: node['mesos']['kafka_servers'].split(',').sample,
  )
end
