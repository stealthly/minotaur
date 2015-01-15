# Generic
default['kafka']['brokers'] = ENV['kafka_brokers'].to_s.empty? ? [ '127.0.0.1'] : ENV['kafka_brokers'].split(',')
default['kafka']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['kafka']['brokers'] : ENV['zk_servers'].split(',')

# Consumer
default['kafka']['consumer']['install_dir'] = '/opt/stealthly/kafka_go_consumer'
default['kafka']['consumer']['url'] = 'https://s3.amazonaws.com/bdoss-deploy/kafka/consumers/go_consumer'
#
default['kafka']['consumer']['client_id'] = "go-consumer"
default['kafka']['consumer']['group_id'] = "stress-test-group"
default['kafka']['consumer']['num_consumers'] = "1"
default['kafka']['consumer']['topic'] = "state"
default['kafka']['consumer']['zookeeper_connect'] = "#{node['kafka']['zk_servers'].sample}:2181"
default['kafka']['consumer']['zookeeper_timeout'] = "1s"
default['kafka']['consumer']['num_workers'] = "1"
default['kafka']['consumer']['max_worker_retries'] = "3"
default['kafka']['consumer']['worker_backoff'] = "500ms"
default['kafka']['consumer']['worker_retry_threshold'] = "100"
default['kafka']['consumer']['worker_considered_failed_time_window'] = "500ms"
default['kafka']['consumer']['worker_batch_timeout'] = "5m"
default['kafka']['consumer']['worker_task_timeout'] = "1m"
default['kafka']['consumer']['worker_managers_stop_timeout'] = "1m"
default['kafka']['consumer']['rebalance_barrier_timeout'] = "10s"
default['kafka']['consumer']['rebalance_max_retries'] = "4"
default['kafka']['consumer']['rebalance_backoff'] = "5s"
default['kafka']['consumer']['partition_assignment_strategy'] = "range"
default['kafka']['consumer']['exclude_internal_topics'] = "true"
default['kafka']['consumer']['num_consumer_fetchers'] = "1"
default['kafka']['consumer']['fetch_batch_size'] = "1000"
default['kafka']['consumer']['fetch_message_max_bytes'] = "5242880"
default['kafka']['consumer']['fetch_min_bytes'] = "1"
default['kafka']['consumer']['fetch_batch_timeout'] = "5s"
default['kafka']['consumer']['requeue_ask_next_backoff'] = "1s"
default['kafka']['consumer']['fetch_wait_max_ms'] = "100"
default['kafka']['consumer']['socket_timeout'] = "30s"
default['kafka']['consumer']['queued_max_messages'] = "3"
default['kafka']['consumer']['refresh_leader_backoff'] = "200ms"
default['kafka']['consumer']['fetch_metadata_retries'] = "3"
default['kafka']['consumer']['fetch_metadata_backoff'] = "500ms"
default['kafka']['consumer']['offsets_storage'] = "zookeeper"
default['kafka']['consumer']['auto_offset_reset'] = "smallest"
default['kafka']['consumer']['offsets_commit_max_retries'] = "5"
default['kafka']['consumer']['graphite_connect'] = "localhost:2003"
default['kafka']['consumer']['flush_interval'] = "10s"
default['kafka']['consumer']['deployment_timeout'] = "0s"

# Local broker
default['kafka_broker']['version'] = '0.8.2-beta'
default['kafka_broker']['scala_version'] = '2.11'
default['kafka_broker']['tarball_url'] = "https://archive.apache.org/dist/kafka/#{node['kafka_broker']['version']}/kafka_#{node['kafka_broker']['scala_version']}-#{node['kafka_broker']['version']}.tgz"
default['kafka_broker']['install_dir'] = "/opt/apache/kafka"

# Docker
default['docker']['package']['repo_url'] = 'https://get.docker.io/ubuntu'
default['docker']['image_cmd_timeout'] = 900

# Java
default['java']['version'] = '7'