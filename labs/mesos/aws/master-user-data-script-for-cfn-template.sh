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
#AURORA_URL="{ "Ref": "AuroraUrl" }"
#MESOS_VERSION="{ "Ref": "MesosVersion" }"
#MARATHON_VERSION="{ "Ref": "MarathonVersion" }"
#MODULES="{ "Ref": "Modules" }"
#ZK_VERSION="{ "Ref": "ZookeeperVersion" }"
#INSTANCE_WAIT_HANDLE_URL="{ "Ref": "WaitForInstanceWaitHandle" }"

WORKING_DIR="/deploy"
REPO_DIR="$WORKING_DIR/repo"
LAB_PATH="labs/mesos"
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
RUBY_URL="https://rvm_io.global.ssl.fastly.net/binaries/ubuntu/14.04/x86_64/ruby-2.1.5.tar.bz2"

# Update repos and install dependencies
apt-get update
apt-get -y install git-core build-essential awscli

# Install rvm for the latest ruby version
command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source /usr/local/rvm/scripts/rvm
echo "$RUBY_URL=1a201d082586036092cfc5b79dd26718" >> /usr/local/rvm/user/md5
echo "$RUBY_URL=91216074cb5f66ef5e33d47e5d3410148cc672dc73cc0d9edff92e00d20c9973bec7ab21a3462ff4e9ff9b23eff952e83b51b96a3b11cb5c23be587046eb0c57" >> /usr/local/rvm/user/sha512
rvm mount -r $RUBY_URL --verify-downloads 1
rvm use 2.1 --default
rvm rubygems current

# Get latest version of jq
wget https://stedolan.github.io/jq/download/linux64/jq -O /usr/local/bin/jq
chmod +x /usr/local/bin/jq

git clone https://git@github.com/stealthly/minotaur.git "$REPO_DIR"

# Install Docker
curl -sSL https://get.docker.com/ubuntu/ | sh

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

# If no zookeeper nodes found - form zookeeper cluster with zk's on mesos masters
# Providing list of zk servers is also mandatory for aurora
NODES_FILTER="Name=tag:Name,Values=mesos-master.$DEPLOYMENT.$ENVIRONMENT"
MESOS_MASTERS=$(aws ec2 describe-instances --region "$REGION" --filters "$NODES_FILTER" --query "$QUERY" | jq --raw-output 'join(",")')

# Run Chef
mesos_version="$MESOS_VERSION" \
marathon_version="$MARATHON_VERSION" \
modules="$MODULES" \
zk_version="$ZK_VERSION" \
mesos_masters="$MESOS_MASTERS" \
zk_servers="$ZK_SERVERS" \
aurora_url="$AURORA_URL" \
chef-solo -c "$REPO_DIR/$LAB_PATH/chef/solo.rb" -j "$REPO_DIR/$LAB_PATH/chef/solo_master.json"

# Wait 1 minute untill marathon is up
sleep 60

# Start mesos-dns on marathon
curl -X POST -H "Content-Type: application/json" http://127.0.0.1:8080/v2/apps -d@/tmp/mesos-dns.json

# Notify wait handle
WAIT_HANDLE_JSON="{\"Status\": \"SUCCESS\", \"Reason\": \"Done\", \"UniqueId\": \"1\", \"Data\": \"$INSTANCE_ID\"}"
curl -X PUT -H 'Content-Type:' --data-binary "$WAIT_HANDLE_JSON" "$INSTANCE_WAIT_HANDLE_URL"

echo END
