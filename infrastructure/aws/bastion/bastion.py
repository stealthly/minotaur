#!/usr/bin/env python
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
from argparse import ArgumentParser
from ..infrastructure import Infrastructure

class Bastion(Infrastructure):
	def __init__(self, environment, region, zone, instance_type, repo_url):
		super(Bastion, self).__init__(environment, deployment='', region=region, zone=zone)
		vpc_id = self.get_vpc(environment).id
		private_subnet_id = self.get_subnet("private." + environment, vpc_id, zone).id
		public_subnet_id = self.get_subnet("public." + environment, vpc_id, zone).id
		topic_arn = self.get_sns_topic("autoscaling-notifications-" + environment)
		for role in self.iam_connection.list_roles()['list_roles_response']['list_roles_result']['roles']:
			if 'bastion' in role['role_name']:
				role_name = role['role_name']
		self.parameters.append(("KeyName",          environment))
		self.parameters.append(("Environment",      environment))
		self.parameters.append(("VpcId",            vpc_id))
		self.parameters.append(("AvailabilityZone", zone))
		self.parameters.append(("PublicSubnetId",   public_subnet_id))
		self.parameters.append(("PrivateSubnetId",  private_subnet_id))
		self.parameters.append(("AsgTopicArn",      topic_arn))
		self.parameters.append(("InstanceType",     instance_type))
		self.parameters.append(("RepoUrl",          repo_url))
		self.parameters.append(("RoleName",         role_name))
		self.stack_name = "-".join([self.lab_dir, environment, region, zone])

parser = ArgumentParser(description='Deploy bastion to an AWS CloudFormation environment.')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
parser.add_argument('-i', '--instance-type', default='m1.small', help='AWS EC2 instance type to deploy')
parser.add_argument('-u', '--repo-url', default='https://git@github.com/stealthly/minotaur.git', help='Public repository url where user info is stored')

def main():
	args, unknown = parser.parse_known_args()
	infrastructure = Bastion(args.environment, args.region, args.availability_zone, args.instance_type, args.repo_url)
	infrastructure.deploy()

if __name__ == '__main__':
	main()
