# Create producer dir
directory node['kafka']['producer']['install_dir'] do
  owner "root"
  group "root"
  mode 0755
  recursive true
end

# Get producer from URL
remote_file "#{node['kafka']['producer']['install_dir']}/producer" do
  action :create_if_missing
  mode 0755
  source node['kafka']['producer']['url']
end

# Generate config
template "#{node['kafka']['producer']['install_dir']}/producers.properties" do
  source  "producers.properties.erb"
  owner 'root'
  group 'root'
  mode  0644
end

# Seelog
template "#{node['kafka']['producer']['install_dir']}/seelog.xml" do
  source  "seelog.xml.erb"
  owner 'root'
  group 'root'
  mode  0644
end