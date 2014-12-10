# Common dependencies
#

include_recipe 'java::default'

# Install gems
%w{ipaddr_extensions zookeeper}.each do |name|
  chef_gem name do
    action :install
  end
end

# Setting Java-related attributes
if node.key?('java') && node['java'].key?('java_home')
  Chef::Log.info("JAVA_HOME = #{node['java']['java_home']}")
  # set in ruby environment for commands like hdfs namenode -format
  ENV['JAVA_HOME'] = node['java']['java_home']
  # set in hadoop_env
  node.set['hadoop']['hadoop_env']['java_home'] = node['java']['java_home']
end

# Override other attributes
node.override['hadoop']['zk_servers']['ips'] = ENV['zk_servers'].to_s.empty? ? [ node['zookeeper']['server'] ] : ENV['zk_servers'].to_s.split(',')

# Override mesos network interface if in vagrant env
vagrant=`grep "vagrant" /etc/passwd >/dev/null && echo -n "yes" || echo -n "no"`
if vagrant == "yes"
    node.override['hadoop']['namenodes']['interface'] = 'eth1'
    node.override['hadoop']['journalnodes']['interface'] = 'eth1'
    node.override['hadoop']['resourcemanagers']['interface'] = 'eth1'
    node.override['hadoop']['datanodes']['interface'] = 'eth1'
end

# Create parent znodes
znode '/chef'
znode '/chef/hadoop'
