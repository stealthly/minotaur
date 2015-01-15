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

class Sns(Infrastructure):
	def __init__(self, environment, region, topic_name):
		super(Sns, self).__init__(environment, deployment='', region=region, zone='')
		self.parameters.append(("TopicName", topic_name+"-"+environment))
		self.stack_name = "-".join([self.lab_dir, topic_name, environment, region])

parser = ArgumentParser(description='Deploy subnet to an AWS CloudFormation environment.')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser.add_argument('-t', '--topic-name', required=True, help='Name of the SNS topic to be created')

def main():
	args, unknown = parser.parse_known_args()
	infrastructure = Sns(args.environment, args.region, args.topic_name)
	infrastructure.deploy()

if __name__ == '__main__':
	main()