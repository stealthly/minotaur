zookeeper-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up a Zookeeper ensemble.

## Usage

```
usage: minotaur.py lab deploy zookeeper [-h] -e ENVIRONMENT -d DEPLOYMENT -r
                                        REGION -z AVAILABILITY_ZONE
                                        [-n NUM_NODES] [-i INSTANCE_TYPE]
                                        [-v ZK_VERSION]

optional arguments:
  -h, --help            show this help message and exit
  -e ENVIRONMENT, --environment ENVIRONMENT
                        CloudFormation environment to deploy to
  -d DEPLOYMENT, --deployment DEPLOYMENT
                        Unique name for the deployment
  -r REGION, --region REGION
                        Geographic area to deploy to
  -z AVAILABILITY_ZONE, --availability-zone AVAILABILITY_ZONE
                        Isolated location to deploy to
  -n NUM_NODES, --num-nodes NUM_NODES
                        Number of instances to deploy
  -i INSTANCE_TYPE, --instance-type INSTANCE_TYPE
                        AWS EC2 instance type to deploy
  -v ZK_VERSION, --zk-version ZK_VERSION
                        The Zookeeper version to deploy
```

**Mandatory arguments:**

`<environment>` - currently we have only **bdoss-dev** environment in VPC, use it

`<deployment>` - this term/option is used to logically separate groups of nodes within environment. Nodes that belong to different deployments won't interact with each other.

`<region>` - VPC is currently deployed in **us-east-1** region

`<availability zone>` - bdoss-dev environment belongs to **us-east-1a** availability zone

**Optional arguments:**

`[number of instances]` defaults to 1

`[instances flavor]` defaults to m1.small

`[zookeeper version]` defaults to 3.4.6

**Example:**

`./minotaur.py lab deploy zookeeper -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -n 3` - this will spin up 3 zookeeper nodes in "testing" deployment.

*NOTICE:* All Zookeeper nodes that belong to the same deployment will form a cluster.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.