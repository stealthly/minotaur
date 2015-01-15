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

# Dealing with relative import
if __name__ == "__main__" and __package__ is None:
    from os import sys, path
    sys.path.append(path.dirname(path.dirname(path.abspath(__file__))))
    from infrastructure import Infrastructure
else:
    from ..infrastructure import Infrastructure

class Subnet(Infrastructure):
	def __init__(self, environment, region, zone, public_private, cidr_block):
		super(Subnet, self).__init__(environment, deployment='', region=region, zone=zone, template="-".join([public_private,'template.cfn']))
		vpc_id = self.get_vpc(environment).id
		self.parameters.append(("Environment",      environment))
		self.parameters.append(("VpcId",            vpc_id))
		self.parameters.append(("AvailabilityZone", zone))
		self.parameters.append(("CidrBlock",        cidr_block))
		self.stack_name = "-".join([self.lab_dir, environment, region, zone, public_private])
		if public_private == 'public':
			internet_gateway_id = self.get_internet_gw(vpc_id).id
			self.parameters.append(("InternetGatewayId", internet_gateway_id))

parser = ArgumentParser(description='Deploy subnet to an AWS CloudFormation environment.')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
parser.add_argument('-p', '--public-private', required=True, help='Network publicity option: public or private')
parser.add_argument('-c', '--cidr-block', required=True, help='Subnet mask of subnet to create')

def main():
	args, unknown = parser.parse_known_args()
	infrastructure = Subnet(args.environment, args.region, args.availability_zone, args.public_private, args.cidr_block)
	infrastructure.deploy()

if __name__ == '__main__':
	main()
