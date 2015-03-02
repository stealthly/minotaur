#!/bin/bash -ex
#
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


# This script is meant to be JSON escaped and pasted into an AWS CloudFormation
# instance's UserData property.

exec > >(tee /var/log/user-data.log) 2>&1

echo BEGIN

# Don't copy the below - each of these needs to be handled out-of-band
#INSTANCE_WAIT_HANDLE_URL="{ "Ref": "WaitForInstanceWaitHandle" }"

# Install cassandra with dependencies
apt-get update
apt-get -y install openjdk-7-jdk openjdk-7-jre
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get update
apt-get -y install dsc20=2.0.11-1 cassandra=2.0.11
echo -e "rpc_address: $(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')" >> /etc/cassandra/cassandra.yaml
service cassandra restart

# Notify wait handle
WAIT_HANDLE_JSON="{\"Status\": \"SUCCESS\", \"Reason\": \"Done\", \"UniqueId\": \"1\", \"Data\": \"$INSTANCE_ID\"}"
curl -X PUT -H 'Content-Type:' --data-binary "$WAIT_HANDLE_JSON" "$INSTANCE_WAIT_HANDLE_URL"

echo END
