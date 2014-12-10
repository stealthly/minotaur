# attributes/default.rb

default[:zookeeper][:version]     = '3.4.6'
default[:zookeeper][:checksum]    = '01b3938547cd620dc4c93efe07c0360411f4a66962a70500b163b59014046994'
default[:zookeeper][:mirror]      = 'https://www.us.apache.org/dist/zookeeper/'

default[:zookeeper][:user]        = 'zookeeper'

default[:zookeeper][:install_dir] = '/opt/apache/zookeeper'
default[:zookeeper][:data_dir] = '/var/lib/zookeeper'

default[:zookeeper][:id] = '0'
default[:zookeeper][:peer_port] = '2888'
default[:zookeeper][:leader_port] = '3888'

default[:zookeeper][:servers] = nil