# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Managing users on bastion host

bag = node['user']['data_bag_name']
environment = ENV['environment'].nil? ? node['environment'] : ENV['environment']

ruby_block "allow-sshd-tcp-forwarding" do
  block do
    file = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
    file.insert_line_if_no_match("^AllowTcpForwarding.*$", "AllowTcpForwarding yes")
    file.write_file
  end
end

template "#{node['working_dir']}/continuous-deploy.sh" do
  source "continuous-deploy.sh.erb"
  mode "0700"
  variables({
    :environment => environment
  })
end

cron "continuous-deploy" do
  action :create
  minute "*/5"
  user "root"
  command "#{node['working_dir']}/continuous-deploy.sh > #{node['working_dir']}/latest-cron-deploy.log 2>&1"
end

# Manage users
data_bag(bag).each do |i|
  u = data_bag_item(bag, i.gsub(/[.]/, '-'))
  username = u['username'] || u['id']

  # Create user if effective environment is in it's envs list
  user_account username do
    %w{comment uid gid home shell password system_user manage_home create_group
        ssh_keys ssh_keygen non_unique}.each do |attr|
      send(attr, u[attr]) if u[attr]
    end
    action :create
    only_if do u['environments'].include? environment end
  end

  # Or remove if not
  user_account username do
    %w{comment uid gid home shell password system_user manage_home create_group
        ssh_keys ssh_keygen non_unique}.each do |attr|
      send(attr, u[attr]) if u[attr]
    end
    action :remove
    not_if do u['environments'].include? environment end
  end
end
