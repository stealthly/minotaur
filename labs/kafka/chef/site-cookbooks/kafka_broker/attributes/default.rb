default[:kafka][:version] = "0.8.2-beta"
default[:kafka][:scala_version] = "2.11"

default[:kafka][:tarball_base] = "kafka_#{node[:kafka][:scala_version]}-#{node[:kafka][:version]}"
default[:kafka][:tarball_name] = "#{node[:kafka][:tarball_base]}.tgz"
default[:kafka][:tarball_url] = "https://archive.apache.org/dist/kafka/#{node[:kafka][:version]}/#{node[:kafka][:tarball_name]}"

default[:kafka][:provided_url] = nil

default[:kafka][:install_dir] = "/opt/apache/kafka"
default[:kafka][:data_dir] = "/var/lib/kafka"
default[:kafka][:log_dir] = "/var/log/kafka"

default[:kafka][:log_flush_interval] = 10000
default[:kafka][:log_flush_time_interval] = 1000
default[:kafka][:log_flush_scheduler_time_interval] = 1000
default[:kafka][:log_retention_hours] = 168

default[:kafka][:user] = "kafka"
default[:kafka][:group] = "kafka"

default[:kafka][:broker_id] = 0
default[:kafka][:port] = 9092
default[:kafka][:jmx_port] = 9999
default[:kafka][:threads] = nil

default[:kafka][:interface] = 'eth0'

default[:kafka][:zk_servers] = nil
default[:kafka][:kafka_brokers] = nil