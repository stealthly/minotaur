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
from ..lab import Lab

class Mesos(Lab):
	def __init__(self, environment, deployment, region, zone, instance_count, instance_type, mesos_version, zk_version, aurora_url):
		super(MesosMaster, self).__init__(environment, deployment, region, zone, template="-".join([sys.argv[4],'template.cfn']))
		vpc_id = self.get_vpc(environment).id
		private_subnet_id = self.get_subnet("private." + environment, vpc_id, zone).id
		topic_arn = self.get_sns_topic("autoscaling-notifications-" + environment)
		role_name = self.get_role_name("GenericDev")
		self.parameters.append(("KeyName",          environment))
		self.parameters.append(("Environment",      environment))
		self.parameters.append(("Deployment",       deployment))
		self.parameters.append(("AvailabilityZone", zone))
		self.parameters.append(("NumberOfNodes",    instance_count))
		self.parameters.append(("InstanceType",     instance_type))
		self.parameters.append(("MesosVersion",     mesos_version))
		self.parameters.append(("ZookeeperVersion", zk_version))
		self.parameters.append(("VpcId",            vpc_id))
		self.parameters.append(("PrivateSubnetId",  private_subnet_id))
		self.parameters.append(("AsgTopicArn",      topic_arn))
		self.parameters.append(("RoleName",         role_name))
		if sys.argv[4] == "master":
			public_subnet_id = self.get_subnet("public." + environment, vpc_id, zone).id
			self.parameters.append(("PublicSubnetId", public_subnet_id))
			self.parameters.append(("AuroraUrl",      aurora_url))  # Needs to be optional in CFN template

parser = ArgumentParser(description='Deploy Mesos Master(s) to an AWS CloudFormation environment.')
subparsers_mesos = parser.add_subparsers()
parser_master = subparsers_mesos.add_parser(name="master", add_help=True)
parser_master.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser_master.add_argument('-d', '--deployment', required=True, help='Unique name for the deployment')
parser_master.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser_master.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
parser_master.add_argument('-n', '--num-nodes', type=int, default=1, help='Number of instances to deploy')
parser_master.add_argument('-i', '--instance-type', default='m1.small', help='AWS EC2 instance type to deploy')
parser_master.add_argument('-m', '--mesos-version', default='0.20.1', help='The Mesos version to deploy')
parser_master.add_argument('-v', '--zk-version', default='3.4.6', help='The Zookeeper version to deploy')
parser_slave = subparsers_mesos.add_parser(name="slave", add_help=False, parents=[parser_master])
parser_master.add_argument('-a', '--aurora-url', default='', help='The Aurora scheduler URL')

def main():
	args, unknown = parser.parse_known_args()
	lab = Mesos(args.environment, args.deployment, args.region, args.availability_zone, 
		str(args.num_nodes), args.instance_type, args.mesos_version, args.zk_version, args.aurora_url)
	lab.deploy()

if __name__ == '__main__':
	main()
