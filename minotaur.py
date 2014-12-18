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
from subprocess import call
import os, sys

# Importing infrastructure modules
inf_dir = os.path.dirname(os.path.realpath(__file__)) + "/infrastructure/aws"
infrastructure_list = [i for i in os.listdir(inf_dir) if os.path.exists(inf_dir+'/'+i+'/'+i+'.py')]
for module in infrastructure_list:
	exec("from infrastructure.aws.{0} import {0}".format(module))

# Importing lab modules
lab_dir = os.path.dirname(os.path.realpath(__file__)) + "/labs"
lab_list = [i for i in os.listdir(lab_dir) if os.path.exists(lab_dir+'/'+i+'/'+i+'.py')]
for module in lab_list:
	exec("from labs.{0} import {0}".format(module))

commands = ["list", "deploy"]
deploy_usage = """usage: minotaur deploy <deployment> [flags...]
"""

class Minotaur:
	def __init__(self):
		parser = ArgumentParser(description="Deploy VPC-based infrastructure and labs based on this infrastructure in AWS")
		subparsers = parser.add_subparsers()
		parser_infrastructure = subparsers.add_parser(name="infrastructure")
		parser_lab = subparsers.add_parser(name="lab")
		subparsers_infrastructure = parser_infrastructure.add_subparsers()
		parser_infrastructure_deploy = subparsers_infrastructure.add_parser(name="deploy")
		parser_infrastructure_list = subparsers_infrastructure.add_parser(name="list")
		subparsers_lab = parser_lab.add_subparsers()
		parser_lab_deploy = subparsers_lab.add_parser(name="deploy")
		parser_lab_list = subparsers_lab.add_parser(name="list")
		subparsers_infrastructure_deploy = parser_infrastructure_deploy.add_subparsers()
		subparsers_lab_deploy = parser_lab_deploy.add_subparsers()
		for module in infrastructure_list:
			exec("parser_{0} = subparsers_infrastructure_deploy.add_parser(name='{0}', add_help=False, parents=[{0}.parser])".format(module))
		for module in lab_list:
			exec("parser_{0} = subparsers_lab_deploy.add_parser(name='{0}', add_help=False, parents=[{0}.parser])".format(module))
		parser_all = subparsers_infrastructure_deploy.add_parser(name="all")
		parser_all.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
		parser_all.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
		parser_all.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
		parser_all.add_argument('-i', '--instance-type', default='m1.small', help='AWS EC2 instance type of nat and bastion instances to deploy')
		self.args, self.unknown = parser.parse_known_args()
		if sys.argv[2] is None:
			print "Available commands are {0}".format(commands)
			exit(1)

	def deploy(self):
		# LIST
		if sys.argv[2] == commands[0]:
			self.print_labs()
		# DEPLOY
		elif sys.argv[2] == commands[1] and sys.argv[1] == "infrastructure":
			if sys.argv[3] == "all":
				sns.Sns(self.args.environment, self.args.region, "cloudformation-notifications").deploy()
				sns.Sns(self.args.environment, self.args.region, "autoscaling-notifications").deploy()
				vpc.Vpc(self.args.environment, self.args.region, "10.0.0.0/21").deploy()
				subnet.Subnet(self.args.environment, self.args.region, self.args.availability_zone, "private", "10.0.0.0/23").deploy()
				subnet.Subnet(self.args.environment, self.args.region, self.args.availability_zone, "public", "10.0.2.0/24").deploy()
				nat.Nat(self.args.environment, self.args.region, self.args.availability_zone, self.args.instance_type).deploy()
				bastion.Bastion(self.args.environment, self.args.region, self.args.availability_zone, self.args.instance_type).deploy()
			elif sys.argv[3] in infrastructure_list:
				exec("{0}.main()".format(sys.argv[3]))
		elif sys.argv[2] == commands[1] and sys.argv[1] == "lab":
			if sys.argv[3] in lab_list:
				exec("{0}.main()".format(sys.argv[3]))

	def print_labs(self):
		if sys.argv[1] == "lab":
			labs = [name for name in os.listdir(lab_dir) if os.path.isdir(lab_dir + "/" + name)]
			print "Available deployments are: {0}".format(labs)
		elif sys.argv[1] == "infrastructure":
			inf = [name for name in os.listdir(inf_dir) if os.path.isdir(inf_dir + "/" + name)]
			print "Available deployments are: {0}".format(inf)

if __name__ == "__main__":
	Minotaur().deploy()
