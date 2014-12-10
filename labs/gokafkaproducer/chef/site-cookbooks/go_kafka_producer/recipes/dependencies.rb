include_recipe 'kafka_broker'

execute "add KAFKA_PATH to env" do
  command "echo KAFKA_PATH=\"#{node['kafka_broker']['install_dir']}\" >> /etc/environment"
  not_if 'grep KAFKA_PATH /etc/environment'
end
