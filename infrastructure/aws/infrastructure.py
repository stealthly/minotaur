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
from boto import cloudformation as cfn, sns, vpc
from boto.exception import BotoServerError
from boto import iam
import os, sys
from time import sleep

vpc_provider = "aws"
template = "template.cfn"
max_template_size = 307200

class Infrastructure(object):
	def __init__(self, environment, deployment, region, zone, template=template):
		# Create connections to AWS components
		self.cfn_connection = cfn.connect_to_region(region)
		self.sns_connection = sns.connect_to_region(region)
		self.vpc_connection = vpc.connect_to_region(region)
		self.iam_connection = iam.connect_to_region("universal")

		# Temporary python class -> directory name hack
		self.lab_dir = self.__class__.__name__.lower()

		self.stack_name = "-".join([self.lab_dir, environment, deployment, region, zone])
		if environment != '':
			self.notification_arns = self.get_sns_topic("cloudformation-notifications-" + environment)
		self.parameters = []

		# Prepare the CFN template
		self.template_url = "/".join([os.path.dirname(os.path.realpath(__file__)), self.lab_dir, vpc_provider, template])
		self.template_body = self.read_file(self.template_url, max_template_size)
		self.validate_template()


	"""
	Create or update an Amazon CloudFormation stack.
	"""
	def deploy(self):
		try:
			if self.stack_exists():
				print "Updating existing '{0}' stack...".format(self.stack_name)
				stack = self.cfn_connection.update_stack(self.stack_name,
					template_body=self.template_body, parameters=self.parameters, capabilities=["CAPABILITY_IAM"])
			elif self.lab_dir in ["sns", "iampolicies", "iamusertogroupadditions"]:
				print "Creating new '{0}' stack...".format(self.stack_name)
				stack = self.cfn_connection.create_stack(self.stack_name,
					template_body=self.template_body, parameters=self.parameters, disable_rollback=True, capabilities=["CAPABILITY_IAM"])
			else:
				print "Creating new '{0}' stack...".format(self.stack_name)
				stack = self.cfn_connection.create_stack(self.stack_name, 
					template_body=self.template_body, parameters=self.parameters,
					notification_arns=self.notification_arns, disable_rollback=True, capabilities=["CAPABILITY_IAM"])
		except BotoServerError as e:
			if "No updates are to be performed" in e.message:
				print "No updates are to be performed"
				return None
			else:
				print "({0}) {1}:\n{2}\nError deploying. Error message: {3}".format(e.status, e.reason, e.body, e.message)
				sys.exit(1)
		# Wait untill stack is created, because infrastructure components relay on each other
		while True:
			event = self.cfn_connection.describe_stacks(self.stack_name)[0].describe_events()[0]
			if event.logical_resource_id == self.stack_name and event.resource_status == "CREATE_COMPLETE":
				print "Stack deployed."
				break
			elif event.logical_resource_id == self.stack_name and event.resource_status == "UPDATE_COMPLETE":
				print "Stack updated."
				break
			elif event.logical_resource_id == self.stack_name and event.resource_status == "CREATE_FAILED":
				print "Error deploying."
				sys.exit(1)
			else:
				sleep(1)
		return stack

	"""
	Determines if a CloudFormation stack exists for a stack name.
	"""
	def stack_exists(self):
		try:
			self.cfn_connection.describe_stacks(stack_name_or_id=self.stack_name)
			return True
		except:
			return False

	"""
	Validates a CloudFormation (CFN) template. 
	If there is an error, communicate the reason and exit (1).
	"""
	def validate_template(self):
		try:
			self.cfn_connection.validate_template(template_body=self.template_body)
			print "Template successfully validated."
		except BotoServerError as e:
			print "({0}) {1}:\n{2}\nError during template validation.".format(e.status, e.reason, e.body)
			sys.exit(1)

	"""
	Read up to max_size bytes from a file and return it as a string.
	"""
	def read_file(self, url, max_size):
		fd = os.open(self.template_url, os.O_RDONLY)
		file_contents = os.read(fd, max_size)
		os.close(fd)
		return file_contents

	"""
	Given a Simple Notification Service (SNS) topic name, return the topic's ARN.
	"""
	def get_sns_topic(self, topic_name):
		for topic in self.sns_connection.get_all_topics()['ListTopicsResponse']['ListTopicsResult']['Topics']:
			if topic_name in topic['TopicArn']:
				return topic['TopicArn']
		print "SNS topic \"{0}\" not found. Is SNS topic \"{0}\" deployed?".format(topic_name)
		return None

	"""
	Given a name, return a Virtual Private Cloud (VPC).
	"""
	def get_vpc(self, vpc_name):
		for vpc in self.vpc_connection.get_all_vpcs():
			try:
				if vpc.tags['Name'] == vpc_name:
					return vpc
			except KeyError:
				continue
		print "VPC \"{0}\" not found. Is VPC \"{0}\" deployed?".format(vpc_name)
		return None

	"""
	Find a subnet by name within a specific VPC and availability zone.
	"""
	def get_subnet(self, subnet_name, vpc_id, zone):
		for subnet in self.vpc_connection.get_all_subnets(filters=[("vpcId", vpc_id), ("availabilityZone", zone)]):
			try:
				if subnet.tags['Name'] == subnet_name:
					return subnet
			except KeyError:
				continue
		print "Subnet \"{0}\" not found. Is subnet \"{0}\" deployed?".format(subnet_name)
		return None

	"""
	Find an internet gateway within a specific VPC.
	"""
	def get_internet_gw(self, vpc_id):
		if len(self.vpc_connection.get_all_internet_gateways(filters=[("attachment.vpc-id", vpc_id)])) == 1:
			return self.vpc_connection.get_all_internet_gateways(filters=[("attachment.vpc-id", vpc_id)])[0]
		else:
			return None

	"""
	Find a route table attached to a specific subnet.
	"""
	def get_route_table(self, subnet_id):
		if len(self.vpc_connection.get_all_route_tables(filters=[("association.subnet-id", subnet_id)])) == 1:
			return self.vpc_connection.get_all_route_tables(filters=[("association.subnet-id", subnet_id)])[0]
		else:
			return None

	"""
	Find a full role name by given partial name.
	"""
	def get_role_name(self, name):
		for role in self.iam_connection.list_roles()['list_roles_response']['list_roles_result']['roles']:
			if name in role['role_name']:
				return role['role_name']
		return None

	"""
	Create default IAM security groups if they are not created.
	"""
	def create_security_groups(self):
		groups = []
		for group in self.iam_connection.get_all_groups()['list_groups_response']['list_groups_result']['groups']:
			groups.append(group['group_name'])
		if 'administrators' not in groups:
			self.iam_connection.create_group('administrators')
			print "\"administrators\" IAM security group was created."
		if 'trusted' not in groups:
			self.iam_connection.create_group('trusted')
			print "\"trusted\" IAM security group was created."
