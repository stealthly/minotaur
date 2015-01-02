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
#REGION="{ "Ref": "AWS::Region" }"
#DEPLOYMENT="{ "Ref": "Deployment" }"
#ENVIRONMENT="{ "Ref": "Environment" }"
#CONSUMER_URL="{ "Ref": "ConsumerUrl" }"
#INSTANCE_WAIT_HANDLE_URL="{ "Ref": "WaitForInstanceWaitHandle" }"

WORKING_DIR="/deploy"
REPO_DIR="$WORKING_DIR/repo"
LAB_PATH="labs/gokafkaconsumer"
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# Update repos and install dependencies
apt-get update
apt-get -y install git-core build-essential awscli

# Install rvm for the latest ruby version
command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby=2.1
source /usr/local/rvm/scripts/rvm
rvm use 2.1 --default
rvm rubygems current

# Get latest version of jq
wget https://stedolan.github.io/jq/download/linux64/jq -O /usr/local/bin/jq
chmod +x /usr/local/bin/jq

mkdir -p "$WORKING_DIR"
chmod 0755 "$WORKING_DIR"

git clone https://git@github.com/stealthly/minotaur.git "$REPO_DIR"

# Install Chef
curl -L https://www.opscode.com/chef/install.sh | bash

# Install Bundler and community cookbooks with librarian
aws s3 cp --region $REGION s3://bdoss-deploy/gems/librarian-0.1.2.gem /tmp/librarian-0.1.2.gem
gem install /tmp/librarian-0.1.2.gem --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc
cd $REPO_DIR/$LAB_PATH/chef/ && bundle install && librarian-chef install

# Find zookeeper nodes that belong to the same deployment and environment
NODES_FILTER="Name=tag:Name,Values=zookeeper.$DEPLOYMENT.$ENVIRONMENT"
QUERY="Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress"
ZK_SERVERS=$(aws ec2 describe-instances --region "$REGION" --filters "$NODES_FILTER" --query "$QUERY" | jq --raw-output 'join(",")')

# Find kafka brokers
NODES_FILTER="Name=tag:Name,Values=kafka.$DEPLOYMENT.$ENVIRONMENT"
KAFKA_BROKERS=$(aws ec2 describe-instances --region "$REGION" --filters "$NODES_FILTER" --query "$QUERY" | jq --raw-output 'join(",")')

# Run Chef
consumer_url="$CONSUMER_URL" \
zk_servers="$ZK_SERVERS" \
kafka_brokers=$"$KAFKA_BROKERS" \
chef-solo -c "$REPO_DIR/$LAB_PATH/chef/solo.rb" -j "$REPO_DIR/$LAB_PATH/chef/solo.json"

# Notify wait handle
WAIT_HANDLE_JSON="{\"Status\": \"SUCCESS\", \"Reason\": \"Done\", \"UniqueId\": \"1\", \"Data\": \"$INSTANCE_ID\"}"
curl -X PUT -H 'Content-Type:' --data-binary "$WAIT_HANDLE_JSON" "$INSTANCE_WAIT_HANDLE_URL"

echo END
