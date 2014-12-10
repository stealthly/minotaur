# Generic
node.default['kafka']['brokers'] = ENV['kafka_brokers'].to_s.empty? ? [ '127.0.0.1'] : ENV['kafka_brokers'].split(',')
node.default['kafka']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['kafka']['brokers'] : ENV['zk_servers'].split(',')

# Producer
node.default['kafka']['producer']['install_dir'] = '/opt/stealthly/kafka_go_producer'
node.default['kafka']['producer']['url'] = 'https://s3.amazonaws.com/bdoss-deploy/kafka/producers/go_producer'
node.default['kafka']['producer']['zookeeper_connect'] = "#{node['kafka']['zk_servers'].sample}:2181"
node.default['kafka']['producer']['broker_connect'] = "#{node['kafka']['brokers'].sample}:9092"
node.default['kafka']['producer']['sleep_time'] = "10ms"
node.default['kafka']['producer']['topic'] = "test"
node.default['kafka']['producer']['num_partitions'] = "6"

# Local broker
default['kafka_broker']['version'] = '0.8.1.1'
default['kafka_broker']['scala_version'] = '2.10'
default['kafka_broker']['tarball_url'] = "https://archive.apache.org/dist/kafka/#{node['kafka_broker']['version']}/kafka_#{node['kafka_broker']['scala_version']}-#{node['kafka_broker']['version']}.tgz"
default['kafka_broker']['install_dir'] = "/opt/apache/kafka"

# Docker
node.default['docker']['package']['repo_url'] = 'https://get.docker.io/ubuntu'
node.default['docker']['image_cmd_timeout'] = 900

# Java
node.default['java']['version'] = '7'