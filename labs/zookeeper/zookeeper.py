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
    from lab import Lab, enable_debug
else:
    from ..lab import Lab, enable_debug

class Zookeeper(Lab):
    def __init__(self, environment, deployment, region, zone,
                 instance_count, instance_type, zk_version):
        super(Zookeeper, self).__init__(environment, deployment, region, zone)
        vpc_id = self.get_vpc(environment).id
        private_subnet_id = self.get_subnet("private." + environment, vpc_id, zone).id
        topic_arn = self.get_sns_topic("autoscaling-notifications-" + environment)
        role_name = self.get_role_name("GenericDev")
        # m1, c1, m2 instances need old paravirtualized ami. New instances need hvm enabled ami.
        if instance_type in ["m1.small", "m1.medium", "m1.large", "m1.xlarge", "c1.medium",
                             "c1.large", "m2.xlarge", "m2.2xlarge", "m2.4xlarge"]:
            virtualization = "paravirt"
        else:
            virtualization = "hvm"
        self.parameters.append(("KeyName",          environment))
        self.parameters.append(("Deployment",       deployment))
        self.parameters.append(("Environment",      environment))
        self.parameters.append(("VpcId",            vpc_id))
        self.parameters.append(("PrivateSubnetId",  private_subnet_id))
        self.parameters.append(("AvailabilityZone", zone))
        self.parameters.append(("ZookeeperVersion", zk_version))
        self.parameters.append(("NumberOfNodes",    instance_count))
        self.parameters.append(("InstanceType",     instance_type))
        self.parameters.append(("AsgTopicArn",      topic_arn))
        self.parameters.append(("RoleName",         role_name))
        self.parameters.append(("Virtualization",   virtualization))

parser = ArgumentParser(description='Deploy ZooKeeper Ensemble to an AWS CloudFormation environment.')
parser.add_argument('--debug', action='store_const', const=True, help='Enable debug mode')
parser.add_argument('-e', '--environment', required=True, help='CloudFormation environment to deploy to')
parser.add_argument('-d', '--deployment', required=True, help='Unique name for the deployment')
parser.add_argument('-r', '--region', required=True, help='Geographic area to deploy to')
parser.add_argument('-z', '--availability-zone', required=True, help='Isolated location to deploy to')
parser.add_argument('-n', '--num-nodes', type=int, default=1, help='Number of instances to deploy')
parser.add_argument('-i', '--instance-type', default='m1.small', help='AWS EC2 instance type to deploy')
parser.add_argument('-v', '--zk-version', default='3.4.6', help='The Zookeeper version to deploy')

def main(parser):
    args, unknown = parser.parse_known_args()
    enable_debug(args)
    lab = Zookeeper(args.environment, args.deployment, args.region, args.availability_zone, 
        str(args.num_nodes), args.instance_type, args.zk_version)
    lab.deploy()

if __name__ == '__main__':
    main(parser)
