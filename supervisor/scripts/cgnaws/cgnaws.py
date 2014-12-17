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

import boto.ec2 as ec2
import time, threading

def establish_connections(accounts):
	connections = {}
	for name in accounts:
		for region in accounts[name]['regions']:
			connections[str(name+'/'+region)] = ec2.connect_to_region(region, aws_access_key_id=accounts[name]['access-key'], \
																	aws_secret_access_key=accounts[name]['secret-key'])
	return connections

def getinfo_thread(initial_data,name,kind,info):
	if kind == 'reservations':
		info[name] = initial_data[name].get_all_instances()
	elif kind == 'instances':
		for instance in initial_data.instances:
			info[name].append(instance)
	else:
		return None

def get_reservations(connections):
	info = {}
	for _,name in enumerate(connections):
		thread_ = threading.Thread(target = getinfo_thread, args = (connections,name,'reservations',info))
		thread_.start()
	while threading.activeCount() > 1:
		pass
	return info

def get_instances(reservations):
	info = {}
	for name in reservations:
		info[name] = []
		for _,reservation in enumerate(reservations[name]):
			thread_ = threading.Thread(target = getinfo_thread, args = (reservation,name,'instances',info))
			thread_.start()
	while threading.activeCount() > 1:
		pass
	return info

def get_instances_info(instances):
	info = {}
	for name in instances:
		info[name] = []
		for instance in instances[name]:
			info[name].append({ 'id' : instance.id, 'type': instance.instance_type, 'state': instance.state, \
					'private-ip': instance.private_ip_address, 'public-ip': instance.ip_address, \
					'public-dns': instance.public_dns_name, 'tags' : instance.tags })
	return info

def print_instances_info(instances_info,search_string=None):
	for cloud_name in instances_info:
		print 'Cloud: ', cloud_name
		table = '{0:35s} {1:12s} {2:14s} {3:15s} {4:15s} {5:15s}'
		print table.format("Name", "Instance ID", "Instance Type", "Instance State", "Private IP", "Public IP")
		print table.format("----", "-----------", "-------------", "--------------", "----------", "---------")
		for instance in instances_info[cloud_name]:
			if search_string != None and \
				search_string not in str(instance['tags']) and \
				search_string not in str(instance['id']) and \
				search_string not in str(instance['private-ip']) and \
				search_string not in str(instance['public-ip']) and \
				search_string not in str(instance['type']):
				continue
			if "Name" in instance["tags"]:
				name = instance["tags"]["Name"]
			else:
				name = "unknown"
			print table.format(name, instance["id"], instance["type"], instance["state"], instance["private-ip"], instance["public-ip"])

def main():
	print '''
	Example:

	import cgnaws
	...	
	accounts = { 'account_name1': { 'regions': ['region1','region2'], 'access-key': 'KEY', 'secret-key': 'SECRET' } 
			'account_name2': { 'regions': ['region1','region2'], 'access-key': 'KEY', 'secret-key': 'SECRET' } }
	...
	connections = cgnaws.establish_connections(accounts)
	reservations = cgnaws.get_reservations(connections)
	instances = cgnaws.get_instances(reservations)
	cgnaws.print_instances_info(cgnaws.get_instances_info(instances),search_string)
	
	# search_string is a part of instance ID, private IP, public DNS name or tag
	# if empty - print brief information about each known instance
	'''

if __name__ == '__main__':
	main()
