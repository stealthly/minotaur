mesos-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up Mesos master and slave nodes.

## Usage
```
usage: minotaur.py lab deploy mesosmaster [-h] -e ENVIRONMENT -d DEPLOYMENT -r
                                          REGION -z AVAILABILITY_ZONE
                                          [-n NUM_NODES] [-i INSTANCE_TYPE]
                                          [-m MESOS_VERSION] [-v ZK_VERSION]
                                          [-a AURORA_URL]

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
  -m MESOS_VERSION, --mesos-version MESOS_VERSION
                        The Mesos version to deploy
  -v ZK_VERSION, --zk-version ZK_VERSION
                        The Zookeeper version to deploy
  -a AURORA_URL, --aurora-url AURORA_URL
                        The Aurora scheduler URL
```
**Mandatory arguments:**

`<environment>` - currently we have only **bdoss-dev** environment in VPC, use it

`<deployment>` - this term/option is used to logically separate groups of nodes within environment. Nodes that belong to different deployments won't interact with each other.

`<region>` - VPC is currently deployed in **us-east-1** region

`<availability zone>` - bdoss-dev environment belongs to **us-east-1a** availability zone

**Optional arguments:**

`[number of nodes]` defaults to 1

`[instances flavor]` defaults to m1.small

`[mesos version]` defaults to 0.20.1

`[zookeeper version]` defaults to 3.4.6

`[aurora url]` defaults to https://s3.amazonaws.com/bdoss-deploy/mesos/aurora/aurora-scheduler-0.6.1.tar

**Example:**

`./minotaur.py lab deploy mesosmaster -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -m 0.20.0 -i m1.small` - this will spin up mesos master (v. 0.20.0) node in "testing" deployment.

`./minotaur.py lab deploy mesosmaster -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -n 3 -i m1.medium` - this will spin up 3 m1.medium mesos slave nodes in "testing" deployment.

*NOTICE:* If you're deploying a cluster - make sure that a separate Zookeeper node is running in the same environment and deployment.

During spin-up procedure, each Mesos node (this also applies to master) will try to reveal all Zookeeper nodes running in the same environment+deployment and will configure itself against them.

If no Zookeeper(s) found - Mesos master will install Zookeeper locally and will rely on it, slaves will configure themselves to use zookeeper on master node.

After pushing master node to CFN, I'd recommend waiting a minute or two before pushing slaves, just to make sure master instance is ready before slaves connect to it.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.