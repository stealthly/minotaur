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
#REGION_ID="{ "Ref": "AWS::Region" }"
#ENVIRONMENT="{ "Ref": "Environment" }"
#PUBLIC_NETWORK_INTERFACE_ID="{ "Ref": "PublicNetworkInterface" }"
#INSTANCE_WAIT_HANDLE_URL="{ "Ref": "WaitForInstanceWaitHandle" }"
#REPO_URL="{ "Ref": "RepoUrl" }"

WORKING_DIR="/deploy"
REPO_DIR="$WORKING_DIR/repo"
BASTION_PATH="infrastructure/aws/bastion"
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

yum -y install git-core

mkdir -p "$WORKING_DIR"
chmod 0755 "$WORKING_DIR"

git clone "$REPO_URL" "$REPO_DIR"

# Install Chef
curl -L https://www.opscode.com/chef/install.sh | bash

# Run Chef
environment=$ENVIRONMENT chef-solo -c "$REPO_DIR/$BASTION_PATH/chef/solo.rb" -j "$REPO_DIR/$BASTION_PATH/chef/solo.json"

# Attach public network interface
aws ec2 attach-network-interface --region "$REGION_ID" --instance-id "$INSTANCE_ID" --network-interface-id "$PUBLIC_NETWORK_INTERFACE_ID" --device-index=1

# Notify wait handle
WAIT_HANDLE_JSON="{\"Status\": \"SUCCESS\", \"Reason\": \"Done\", \"UniqueId\": \"1\", \"Data\": \"$INSTANCE_ID\"}"
curl -X PUT -H 'Content-Type:' --data-binary "$WAIT_HANDLE_JSON" "$INSTANCE_WAIT_HANDLE_URL"

echo END
