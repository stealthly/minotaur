default[:mesos][:mirror] = 'http://downloads.mesosphere.io/'
default[:mesos][:version] = '0.21.0'
default[:mesos][:subversion] = '1.0'

default[:mesos][:work_dir] = '/mnt/mesos'
default[:mesos][:log_dir] = '/var/log/mesos'

default[:mesos][:set_ec2_hostname] = true

default[:mesos][:slaves] = nil
default[:mesos][:masters] = nil
default[:mesos][:masters_eip] = nil

default[:mesos][:cluster_name] = 'stealth.ly'

default[:mesos][:master][:interface] = 'eth0'
default[:mesos][:slave][:interface] = 'eth0'
default[:mesos][:port] = 5050

default[:mesos][:master][:hostname] = 'mesos-master'
default[:mesos][:slave][:hostname] = 'mesos-slave'

default[:mesos][:master][:attributes][:work_dir] = default[:mesos][:work_dir]

default[:mesos][:slave][:attributes][:checkpoint] = 'true'
default[:mesos][:slave][:attributes][:strict] = 'false'
default[:mesos][:slave][:attributes][:recover] = 'reconnect'
default[:mesos][:slave][:attributes][:containerizers] = 'docker,mesos'
default[:mesos][:slave][:attributes][:executor_registration_timeout] = '5mins'

default[:mesos][:mount_point] = default[:mesos][:work_dir]
default[:mesos][:volume_label] = 'mesos-fs'
default[:mesos][:device_id] = '/dev/xvdc'

default[:mesos][:slave][:isolation_type] = 'cgroups/cpu,cgroups/mem'

default[:mesos][:marathon][:version] = '0.7.5'
default[:mesos][:marathon][:subversion] = '1.0'
default[:mesos][:marathon][:attributes][:framework_name] = 'marathon'
default[:mesos][:marathon][:haproxy_bridge_url] = 'https://raw.githubusercontent.com/mesosphere/marathon/master/bin/haproxy-marathon-bridge'

default[:mesos][:aurora][:version] = '0.6.1'
default[:mesos][:aurora][:tarball_name] = "aurora-scheduler-#{node[:mesos][:aurora][:version]}.tar"
default[:mesos][:aurora][:tarball_url] = "https://s3.amazonaws.com/bdoss-deploy/mesos/aurora/#{node[:mesos][:aurora][:tarball_name]}"
default[:mesos][:aurora][:install_dir] = '/opt/apache/aurora'
default[:mesos][:aurora][:http_port] = 8081

default[:mesos][:dns][:bin_url] = "https://s3.amazonaws.com/bdoss-deploy/mesos/mesos-dns/mesos-dns"
default[:mesos][:dns][:install_dir] = '/usr/local/mesos-dns'

default[:mesos][:spark][:install_dir] = '/opt/spark'
default[:mesos][:spark][:version] = '1.2.1'
default[:mesos][:spark][:tarball_url] = "http://d3kbcqa49mib13.cloudfront.net/spark-#{node[:mesos][:spark][:version]}-bin-hadoop2.4.tgz"

default[:mesos][:mirrormaker][:bin_url] = "https://s3.amazonaws.com/bdoss-deploy/kafka/mirrormaker/mirror_maker"

default[:mesos][:gauntlet][:install_dir] = '/opt/gauntlet'

default[:java][:jdk_version] = '7'

default[:mesos][:zk_servers] = nil
default[:mesos][:zookeeper_port] = 2181
default[:mesos][:zookeeper_path] = 'mesos'

default[:zookeeper][:install_dir] = '/opt/apache/zookeeper'
default[:zookeeper][:data_dir] = '/var/lib/zookeeper'
default[:zookeeper][:id] = '0'
default[:zookeeper][:peer_port] = '2888'
default[:zookeeper][:leader_port] = '3888'

default[:route53][:zone_name] = nil
