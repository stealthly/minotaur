# Install gauntlet
#

node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['cassandra_servers'] = ENV['cassandra_servers'].to_s.empty? ? node['mesos']['cassandra_servers'] : ENV['cassandra_servers']
node.override['mesos']['kafka_servers'] = ENV['kafka_servers'].to_s.empty? ? node['mesos']['kafka_servers'] : ENV['kafka_servers']

git node['mesos']['gauntlet']['install_dir'] do
  repository "git@github.com:stealthly/gauntlet.git"
  revision "master"
  action :sync
end

template "#{node['mesos']['gauntlet']['install_dir']}/run.sh" do
  source 'gauntlet/run.sh.erb'
  variables(
    zk_servers: node['mesos']['zk_servers'],
    cassandra_servers: node['mesos']['cassandra_servers'].sample,
    spark_install_dir: node['mesos']['spark']['install_dir']
  )
  mode '0755'
end

template "#{node['mesos']['gauntlet']['install_dir']}/producer.properties" do
  source 'gauntlet/producer.properties.erb'
  variables(
    kafka_servers: node['mesos']['kafka_servers'].sample,
  )
end

template "#{node['mesos']['gauntlet']['install_dir']}/generator-producer.sh" do
  source 'gauntlet/generator-producer.sh.erb'
  variables(
    kafka_servers: node['mesos']['kafka_servers'].sample,
  )
  mode '0755'
end
