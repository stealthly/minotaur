default[:mesos][:mirror] = 'http://downloads.mesosphere.io/'
default[:mesos][:version] = '0.21.0'
default[:mesos][:subversion] = '1.0'

default[:mesos][:work_dir] = '/var/lib/mesos'
default[:mesos][:log_dir] = '/var/log/mesos'

default[:mesos][:masters] = nil

default[:mesos][:cluster_name] = 'stealth.ly'

default[:mesos][:master][:interface] = 'eth0'
default[:mesos][:slave][:interface] = 'eth0'
default[:mesos][:port] = 5050

default[:mesos][:master][:hostname] = 'mesos-master'
default[:mesos][:slave][:hostname] = 'mesos-slave'

default[:mesos][:slave][:attributes][:checkpoint] = 'true'
default[:mesos][:slave][:attributes][:strict] = 'false'
default[:mesos][:slave][:attributes][:recover] = 'reconnect'
default[:mesos][:slave][:attributes][:containerizers] = 'mesos,docker'

default[:mesos][:slave][:isolation_type] = 'cgroups/cpu,cgroups/mem'

default[:mesos][:marathon][:version] = '0.7.5'
default[:mesos][:marathon][:subversion] = '1.0'

default[:mesos][:aurora][:version] = '0.6.1'
default[:mesos][:aurora][:tarball_name] = "aurora-scheduler-#{node[:mesos][:aurora][:version]}.tar"
default[:mesos][:aurora][:tarball_url] = "https://s3.amazonaws.com/bdoss-deploy/mesos/aurora/#{node[:mesos][:aurora][:tarball_name]}"
default[:mesos][:aurora][:install_dir] = '/opt/apache/aurora'
default[:mesos][:aurora][:http_port] = 8081

default[:java][:jdk_version] = '7'

default[:mesos][:zk_servers] = nil
default[:mesos][:zookeeper_port] = 2181
default[:mesos][:zookeeper_path] = 'mesos'

default[:zookeeper][:install_dir] = '/opt/apache/zookeeper'
default[:zookeeper][:data_dir] = '/var/lib/zookeeper'
default[:zookeeper][:id] = '0'
default[:zookeeper][:peer_port] = '2888'
default[:zookeeper][:leader_port] = '3888'