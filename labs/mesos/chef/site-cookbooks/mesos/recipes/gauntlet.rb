# Install gauntlet
#

node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['cassandra_master'] = ENV['cassandra_master'].to_s.empty? ? node['mesos']['cassandra_master'] : ENV['cassandra_master']
node.override['mesos']['kafka_servers'] = ENV['kafka_servers'].to_s.empty? ? node['mesos']['kafka_servers'] : ENV['kafka_servers']

git node['mesos']['gauntlet']['install_dir'] do
  repository "http://github.com/stealthly/gauntlet"
  action :sync
end

ruby_block "template validate.sh" do
  block do
    file = Chef::Util::FileEdit.new("#{node['mesos']['gauntlet']['install_dir']}/validate.sh")
    file.search_file_replace(/export SPARK_PATH.*/, "export SPARK_PATH=\"#{node['mesos']['spark']['install_dir']}\"")
    file.search_file_replace(/export MESOS_MASTER_URL.*/, "export SPARK_MASTER_URL=\"#{node['mesos']['zk_servers'].split(',').join(':2181,')}:2181\"")
    file.search_file_replace(/export CASSANDRA_HOST.*/, "export CASSANDRA_HOST=\"#{node['mesos']['cassandra_master']}\"")
    file.search_file_replace(/export ZK_CONNECT.*/, "export ZK_CONNECT=\"#{node['mesos']['zk_servers'].split(',').sample}:2181\"")
    file.search_file_replace(/export KAFKA_CONNECT.*/, "export KAFKA_CONNECT=\"#{node['mesos']['kafka_servers'].split(',').sample}:9092\"")
    file.write_file
  end
end

ruby_block "template run.sh" do
  block do
    file = Chef::Util::FileEdit.new("#{node['mesos']['gauntlet']['install_dir']}/run.sh")
    file.search_file_replace(/export ZK_CONNECT.*/, "export ZK_CONNECT=\"#{node['mesos']['zk_servers'].split(',').sample}:2181\"")
    file.search_file_replace(/export KAFKA_CONNECT.*/, "export KAFKA_CONNECT=\"#{node['mesos']['kafka_servers'].split(',').sample}:9092\"")
    file.write_file
  end
end

file "#{node['mesos']['gauntlet']['install_dir']}/run.sh" do
  action :create
  mode '0755'
end

file "#{node['mesos']['gauntlet']['install_dir']}/validate.sh" do
  action :create
  mode '0755'
end

ruby_block "template producer.properties" do
  block do
    file = Chef::Util::FileEdit.new("#{node['mesos']['gauntlet']['install_dir']}/producer.properties")
    file.search_file_replace(/metadata\.broker\.list.*/, "metadata.broker.list=#{node['mesos']['kafka_servers'].split(',').join(':9092,')}:9092")
    file.write_file
  end
end
