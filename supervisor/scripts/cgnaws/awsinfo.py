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

with open("/root/.aws/config") as f:
    for line in f.readlines():
        if line.startswith('aws_access_key_id'):
            aws_access_key_id = line.split()[-1]
        elif line.startswith('aws_secret_access_key'):
            aws_secret_access_key = line.split()[-1]

accounts = { 'bdoss' : { 'regions': ['us-east-1'], 'access-key' : aws_access_key_id, 'secret-key' : aws_secret_access_key} }

def main():
    if len(sys.argv) != 1:
        search_string = sys.argv[1]
    else:
        search_string = None
    connections = establish_connections(accounts)
    reservations = get_reservations(connections)
    instances = get_instances(reservations)
    print_instances_info(get_instances_info(instances),search_string)

if __name__ == '__main__':
    main()
