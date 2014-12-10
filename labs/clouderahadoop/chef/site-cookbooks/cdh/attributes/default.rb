# Zookeeper
default[:zookeeper][:mirror] = 'https://www.us.apache.org/dist/zookeeper'
default[:zookeeper][:version] = '3.4.6'
default[:zookeeper][:install_dir] = '/opt/apache/zookeeper'
default[:zookeeper][:server] = '127.0.0.1'

# Hadoop
default[:hadoop][:distribution] = 'cdh'
default[:hadoop][:dns][:clustername] = 'hadoop.stealth.ly'

# env
default[:hadoop][:hadoop_env][:hadoop_opts] = "-Djava.net.preferIPv4Stack=true $HADOOP_OPTS"
default[:hadoop][:hadoop_env][:hadoop_classpath] = "${HADOOP_CLASSPATH}:/usr/share/java/zookeeper.jar"

# namenodes
default[:hadoop][:namenodes][:interface] = 'eth0'
default[:hadoop][:namenodes][:dns][:basename] = 'namenode'

# journalnodes
default[:hadoop][:journalnodes][:interface] = 'eth0'
default[:hadoop][:journalnodes][:dns][:basename] = 'jnode'

# resourcemanagers
default[:hadoop][:resourcemanagers][:interface] = 'eth0'
default[:hadoop][:resourcemanagers][:dns][:basename] = 'rmanager'

# datanodes
default[:hadoop][:datanodes][:interface] = 'eth0'
default[:hadoop][:datanodes][:dns][:basename] = 'datanode'

# zookeepers
default[:hadoop][:zookeepers][:dns][:basename] = 'zookeeper'

# etc
default[:java][:jdk_version] = '7'
