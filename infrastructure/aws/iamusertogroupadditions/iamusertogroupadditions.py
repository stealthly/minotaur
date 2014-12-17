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

class Iamusertogroupadditions(Infrastructure):
	def __init__(self, environment, region):
		super(Iamusertogroupadditions, self).__init__(environment, deployment='', region=region, zone='')
		self.stack_name = "iam-user-to-group-additions"

parser = ArgumentParser(description='Deploy iam user to group additions to an AWS CloudFormation environment.')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')

def main():
	args, unknown = parser.parse_known_args()
	infrastructure = Iamusertogroupadditions(args.environment, args.region)
	infrastructure.deploy()

if __name__ == '__main__':
	main()
