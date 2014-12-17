kafka-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up Kafka-broker nodes.

## Usage

```
usage: minotaur.py lab deploy kafka [-h] -e ENVIRONMENT -d DEPLOYMENT -r
                                    REGION -z AVAILABILITY_ZONE [-n NUM_NODES]
                                    [-i INSTANCE_TYPE] [-v ZK_VERSION]
                                    [-k KAFKA_URL]

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
  -k KAFKA_URL, --kafka-url KAFKA_URL
                        The Kafka URL
```

**Mandatory arguments:**

`<environment>` - currently we have only **bdoss-dev** environment in VPC, use it

`<deployment>` - this term/option is used to logically separate groups of nodes within environment. Nodes that belong to different deployments won't interact with each other.

`<region>` - VPC is currently deployed in **us-east-1** region

`<availability zone>` - bdoss-dev environment belongs to **us-east-1a** availability zone

**Optional arguments:**

`[number of instances]` defaults to 1

`[instances flavor]` defaults to m1.small

`[source url]` defaults to https://archive.apache.org/dist/kafka/0.8.0/kafka_2.8.0-0.8.0.tar.gz

**Example:**

`./minotaur.py lab deploy kafka -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -k http://example.com/kafka.tar.gz -n 3 -i m1.small` - this will spin up 3 kafka-broker nodes in "testing" deployment.

*NOTICE:* If you're deploying a cluster - make sure that a separate Zookeeper node is running in the same environment and deployment.

During spin-up procedure, each Kafka node will try to reveal all Zookeeper nodes running in the same environment+deployment and will configure itself against them.

If no Zookeeper(s) found - each Kafka node will install Zookeeper locally and will rely on it.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.