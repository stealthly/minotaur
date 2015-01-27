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

class Iamusertogroupadditions(Infrastructure):
	def __init__(self):
		super(Iamusertogroupadditions, self).__init__(environment='', deployment='', region='us-east-1', zone='')
		self.stack_name = "iam-user-to-group-additions"

parser = ArgumentParser(description='Deploy iam user to group additions to an AWS CloudFormation environment.')

def main(parser):
	args, unknown = parser.parse_known_args()
	infrastructure = Iamusertogroupadditions()
	infrastructure.deploy()

if __name__ == '__main__':
	main(parser)
