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

class MesosSlave(Lab):
	def __init__(self, environment, deployment, region, zone, instance_count, instance_type, mesos_version, zk_version):
		super(MesosSlave, self).__init__(environment, deployment, region, zone)
		vpc_id = self.get_vpc(environment).id
		private_subnet_id = self.get_subnet("private." + environment, vpc_id, zone).id
		topic_arn = self.get_sns_topic("autoscaling-notifications-" + environment)
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

parser = ArgumentParser(description='Deploy Mesos Slave(s) to an AWS CloudFormation environment.')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-d', '--deployment', required=True, help='Unique name for the deployment')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
parser.add_argument('-n', '--num-nodes', type=int, default=1, help='Number of instances to deploy')
parser.add_argument('-i', '--instance-type', default='m1.small', help='AWS EC2 instance type to deploy')
parser.add_argument('-m', '--mesos-version', default='0.20.1', help='The Mesos version to deploy')
parser.add_argument('-v', '--zk-version', default='3.4.6', help='The Zookeeper version to deploy')

def main():
	args, unknown = parser.parse_known_args()
	lab = MesosSlave(args.environment, args.deployment, args.region, args.availability_zone, 
		str(args.num_nodes), args.instance_type, args.mesos_version, args.zk_version)
	lab.deploy()

if __name__ == '__main__':
	main()
