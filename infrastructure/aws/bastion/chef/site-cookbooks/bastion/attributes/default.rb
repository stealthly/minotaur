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

# Overriding attributes from user cookbook
default['user']['manage_home'] = "false"
default['user']['ssh_keygen'] = "false"
default['user']['data_bag_name'] = "users"
default['environment'] = "vagrant"
default['working_dir'] = "/deploy"
default['git_ssh_wrapper'] = "#{default['working_dir']}/git-ssh-wrapper.sh"
default['repo_dir'] = "#{default['working_dir']}/repo"
default['bastion_path'] = "infrastructure/aws/bastion"
