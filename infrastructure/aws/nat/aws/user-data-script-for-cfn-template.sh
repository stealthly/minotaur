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

# Don't copy the below - each of these needs to be handled out-of-band
#export AWS_DEFAULT_REGION="{ "Ref": "AWS::Region" }"
#ROUTE_TABLE_ID="{ "Ref": "PrivateRouteTableId" }"
#INSTANCE_WAIT_HANDLE_URL={ "Ref": "WaitForInstanceWaitHandle" }

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
DESCRIBE_INTERFACES_RESPONSE=$(aws ec2 describe-network-interfaces --filters "{\"Name\":\"attachment.instance-id\", \"Values\":[\"$INSTANCE_ID\"]}")

yum -y install jq

NETWORK_INTERFACE_ID=$(echo "$DESCRIBE_INTERFACES_RESPONSE" | jq --raw-output ".[\"NetworkInterfaces\"][0][\"NetworkInterfaceId\"]")
DESCRIBE_ROUTE_TABLES_RESPONSE=$(aws ec2 describe-route-tables --filters "{\"Name\":\"route-table-id\", \"Values\":[\"$ROUTE_TABLE_ID\"]}")

# Delete existing route in route table
if [[ $DESCRIBE_ROUTE_TABLES_RESPONSE == *"0.0.0.0"* ]]
then aws ec2 delete-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0
fi

# Create new route in route table
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --network-interface-id $NETWORK_INTERFACE_ID
aws ec2 modify-network-interface-attribute --network-interface-id $NETWORK_INTERFACE_ID --source-dest-check "{\"Value\": false}"

# Notify wait handle
WAIT_HANDLE_JSON="{\"Status\": \"SUCCESS\", \"Reason\": \"Done\", \"UniqueId\": \"1\", \"Data\": \"$INSTANCE_ID\"}"
curl -X PUT -H 'Content-Type:' --data-binary "$WAIT_HANDLE_JSON" "$INSTANCE_WAIT_HANDLE_URL"

echo END
