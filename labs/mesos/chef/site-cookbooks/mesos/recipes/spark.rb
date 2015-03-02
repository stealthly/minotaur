# Install spark framework on mesos
#

node.override['mesos']['zk_servers'] = ENV['zk_servers'].to_s.empty? ? node['mesos']['zk_servers'] : ENV['zk_servers']
node.override['mesos']['spark']['tarball_url'] = ENV['spark_url'].to_s.empty? ? node['mesos']['spark']['tarball_url'] : ENV['spark_url']

# Create working directory
directory node[:mesos][:spark][:install_dir] do
  owner 'root'
  group 'root'
  recursive true
end

remote_file "#{node[:mesos][:spark][:install_dir]}/spark.tar.gz" do
  action :create_if_missing
  source node[:mesos][:spark][:tarball_url]
  not_if { ::File.directory?("#{node[:mesos][:spark][:install_dir]}/bin") }
end

execute "extract spark" do
  command "tar -xvzf spark.tar.gz"
  cwd node[:mesos][:spark][:install_dir]
  creates "#{node[:mesos][:spark][:install_dir]}/bin"
end

file "#{node[:mesos][:spark][:install_dir]}/spark.tar" do
  action :delete
end

template "#{node['mesos']['spark']['install_dir']}/conf/spark-defaults.conf" do
  source 'spark/spark-defaults.conf.erb'
  variables(
    zk_servers: node['mesos']['zk_servers'],
    spark_url: node['mesos']['spark']['tarball_url']
  )
end

template "#{node['mesos']['spark']['install_dir']}/conf/spark-env.sh" do
  source 'spark/spark-env.sh.erb'
  variables(
    zk_servers: node['mesos']['zk_servers'],
    spark_url: node['mesos']['spark']['tarball_url']
  )
  mode '0755'
end
