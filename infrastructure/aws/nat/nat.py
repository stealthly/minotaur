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
    from infrastructure import Infrastructure, enable_debug
else:
    from ..infrastructure import Infrastructure, enable_debug

class Nat(Infrastructure):
    def __init__(self, environment, region, zone, instance_type):
        super(Nat, self).__init__(environment, deployment='', region=region, zone=zone)
        vpc_id = self.get_vpc(environment).id
        private_subnet_id = self.get_subnet("private." + environment, vpc_id, zone).id
        public_subnet_id = self.get_subnet("public." + environment, vpc_id, zone).id
        private_route_table_id = self.get_route_table(private_subnet_id).id
        topic_arn = self.get_sns_topic("autoscaling-notifications-" + environment)
        role_name = self.get_role_name(self.__class__.__name__)
        self.parameters.append(("KeyName",             environment))
        self.parameters.append(("Environment",         environment))
        self.parameters.append(("VpcId",               vpc_id))
        self.parameters.append(("InstanceType",        instance_type))
        self.parameters.append(("PublicSubnetId",      public_subnet_id))
        self.parameters.append(("PrivateRouteTableId", private_route_table_id))
        self.parameters.append(("AvailabilityZone",    zone))
        self.parameters.append(("AsgTopicArn",         topic_arn))
        self.parameters.append(("RoleName",            role_name))
        self.stack_name = "-".join([self.lab_dir, environment, region, zone])

parser = ArgumentParser(description='Deploy nat to an AWS CloudFormation environment.')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
parser.add_argument('-i', '--instance-type', default='m1.small', help='AWS EC2 instance type to deploy')

def main():
    args, unknown = parser.parse_known_args()
    enable_debug(args)
    infrastructure = Nat(args.environment, args.region, args.availability_zone, args.instance_type)
    infrastructure.deploy()

if __name__ == '__main__':
    main()
