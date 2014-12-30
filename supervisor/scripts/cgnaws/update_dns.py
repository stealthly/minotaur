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
from cgnaws import *
import sys
import requests
import json

with open("/root/.aws/config") as f:
    for line in f.readlines():
        if line.startswith('aws_access_key_id'):
            aws_access_key_id = line.split()[-1]
        elif line.startswith('aws_secret_access_key'):
            aws_secret_access_key = line.split()[-1]

accounts = { 'bdoss' : { 'regions': ['us-east-1'], 'access-key' : aws_access_key_id, 'secret-key' : aws_secret_access_key} }

def get_instances_info(instances):
    info = {}
    for name in instances:
        info[name] = []
        for instance in instances[name]:
            info[name].append({ 'availability-zone' : instance.placement, 'region': instance.region.name, 'state': instance.state, \
                    'private-ip': instance.private_ip_address, 'tags' : instance.tags, 'id' : instance.id })
    return info

def main():
    connections = establish_connections(accounts)
    reservations = get_reservations(connections)
    instances = get_instances(reservations)
    instances_info = get_instances_info(instances)
    for cloud_name in instances_info:
        for instance in instances_info[cloud_name]:
            if "Name" in instance["tags"]:
                if '.' in instance["tags"]["Name"]:
                    environment = instance["tags"]["Name"].split('.')[-1]
                else:
                    environment = None
            else:
                environment = None
            if instance["private-ip"] == None:
                continue
            # Create dns entry
            hostname = {"host": instance["private-ip"]}
            payload = {"value": json.dumps(hostname), "ttl": 100}
            if environment != None:
                url = '/'.join(["http://127.0.0.1:4001/v2/keys/skydns/aws", environment, "ip-"+instance["private-ip"].replace('.', '-')])
            else:
                url = '/'.join(["http://127.0.0.1:4001/v2/keys/skydns/aws", "ip-"+instance["private-ip"].replace('.', '-')])
            r = requests.put(url, params=payload)
            print r.text
            # Create reverse dns entry
            if environment != None:
                hostname = {"host": '.'.join(["ip-"+instance["private-ip"].replace('.', '-'), environment, "aws"])}
            else:
                hostname = {"host": '.'.join(["ip-"+instance["private-ip"].replace('.', '-'), "aws"])}
            payload = {"value": json.dumps(hostname), "ttl": 100}
            url = '/'.join(["http://127.0.0.1:4001/v2/keys/skydns/arpa/in-addr", instance["private-ip"].replace('.', '/')])
            r = requests.put(url, params=payload)
            print r.text

if __name__ == '__main__':
    main()
