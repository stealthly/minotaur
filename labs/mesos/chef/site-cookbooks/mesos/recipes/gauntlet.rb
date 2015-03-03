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

bash 'checkout to development repository' do
  user 'root'
  cwd node['mesos']['gauntlet']['install_dir']
  code "git checkout -b poison_pill origin/poison_pill"
  not_if "git status | grep poison_pill", :cwd => node['mesos']['gauntlet']['install_dir']
end

ruby_block "template validate.sh" do
  block do
    file = Chef::Util::FileEdit.new("#{node['mesos']['gauntlet']['install_dir']}/validate.sh")
    file.search_file_replace("/SPARK_PATH=\".*\"/", "SPARK_PATH=#{node['mesos']['spark']['install_dir']}")
    file.search_file_replace("/SPARK_MASTER_URL=\".*\"/", "SPARK_MASTER_URL=#{node['mesos']['zk_servers'].split(',').join(':2181,')}:2181")
    file.search_file_replace("/CASSANDRA_HOST=\".*\"/", "CASSANDRA_HOST=\"#{node['mesos']['cassandra_servers']}\"")
    file.search_file_replace("/ZK_CONNECT=\".*\"/", "ZK_CONNECT=#{node['mesos']['zk_servers'].split(',').sample}:2181")
    file.search_file_replace("/KAFKA_CONNECT=\".*\"/", "KAFKA_CONNECT=#{node['mesos']['kafka_servers'].split(',').sample}:9092")
    file.write_file
  end
end

ruby_block "template run.sh" do
  block do
    file = Chef::Util::FileEdit.new("#{node['mesos']['gauntlet']['install_dir']}/run.sh")
    file.search_file_replace("/ZK_CONNECT=\".*\"/", "ZK_CONNECT=#{node['mesos']['zk_servers'].split(',').sample}:2181")
    file.search_file_replace("/KAFKA_CONNECT=\".*\"/", "KAFKA_CONNECT=#{node['mesos']['kafka_servers'].split(',').sample}:9092")
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

template "#{node['mesos']['gauntlet']['install_dir']}/producer.properties" do
  source 'gauntlet/producer.properties.erb'
  variables(
    kafka_servers: node['mesos']['kafka_servers'].split(',').sample,
  )
end

template "#{node['mesos']['gauntlet']['install_dir']}/generator-producer.sh" do
  source 'gauntlet/generator-producer.sh.erb'
  variables(
    kafka_servers: node['mesos']['kafka_servers'].split(',').sample,
  )
  mode '0755'
end
