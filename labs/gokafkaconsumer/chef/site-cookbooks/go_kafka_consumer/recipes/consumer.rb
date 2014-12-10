# Create consumer dir
directory node['kafka']['consumer']['install_dir'] do
  owner "root"
  group "root"
  mode 0755
  recursive true
end

# Get consumer from URL
remote_file "#{node['kafka']['consumer']['install_dir']}/consumer" do
  action :create_if_missing
  mode 0755
  source node['kafka']['consumer']['url']
end

# Generate config
template "#{node['kafka']['consumer']['install_dir']}/consumers.properties" do
  source  "consumers.properties.erb"
  owner 'root'
  group 'root'
  mode  0644
end

# Seelog
template "#{node['kafka']['consumer']['install_dir']}/seelog.xml" do
  source  "seelog.xml.erb"
  owner 'root'
  group 'root'
  mode  0644
end
