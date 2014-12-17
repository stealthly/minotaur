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

require 'chef/version_constraint'

file_cache_path    "/var/chef/cache"
file_backup_path   "/var/chef/backup"
cookbook_path   [ "/deploy/repo/infrastructure/aws/bastion/chef/cookbooks", "/deploy/repo/infrastructure/aws/bastion/chef/site-cookbooks" ]
data_bag_path   "/deploy/repo/infrastructure/aws/bastion/chef/data_bags"

log_level :info
verbose_logging    false

encrypted_data_bag_secret nil

http_proxy nil
http_proxy_user nil
http_proxy_pass nil
https_proxy nil
https_proxy_user nil
https_proxy_pass nil
no_proxy nil

if Chef::VersionConstraint.new("< 11.8.0").include?(Chef::VERSION)
  role_path nil
else
  role_path []
end
