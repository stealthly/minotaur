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
from argparse import ArgumentParser
import fileinput
import re, sys

with open("/root/.aws/config") as f:
    for line in f.readlines():
        if line.startswith('aws_access_key_id'):
            aws_access_key_id = line.split()[-1]
        elif line.startswith('aws_secret_access_key'):
            aws_secret_access_key = line.split()[-1]

accounts = { 'bdoss' : { 'regions': ['us-east-1'], 'access-key' : aws_access_key_id, 'secret-key' : aws_secret_access_key} }

def get_ip(environment):
    connections = establish_connections(accounts)
    reservations = get_reservations(connections)
    instances = get_instances(reservations)
    for i in instances.values()[0]:
        if i._state.name == 'running' and i.tags['Name'] == "bastion."+environment:
            return [j.publicIp for j in i.interfaces if 'publicIp' in j.__dict__.keys()][0]

pattern = re.compile("[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|BASTION_IP")

if __name__ == "__main__":
    parser = ArgumentParser(description="Template ssh config file with bastion IP in arbitrary environment")
    parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment where bastion is deployed')
    args = parser.parse_args()
    try:
        bastion_ip = get_ip(args.environment)
        print "Bastion IP: "+get_ip(args.environment)
    except:
        print("Failed to fetch bastion public IP")
        sys.exit(1)
    for line in fileinput.input("/root/.ssh/config", inplace=True):
        if pattern.search(line):
            line = line.replace(pattern.findall(line)[0], bastion_ip)
        print(line.rstrip())
    print "SSH config was successfuly templated"
