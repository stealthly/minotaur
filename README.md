dexter
======

This repo constains scripts/recipes/configs to spin up VPC-based infrastructure in AWS from scratch and deploy labs to it.

###Getting started with AWS
Before actually spinning instances up or managing infrastructure, you'll need:

- aws-cli tools installed and configured with your credentials
- jq tool (https://stedolan.github.io/jq/)
- IAM permissions to use CloudFormation

Alternatively, you can use Supervisor image to manage AWS-related stuff.

Optionally you might also want to register your account on Bastion, to have SSH access to instances. 
Info about how to do it can be found in README in infrastructure/aws/bastion folder.

###CloudFormation basics
CFN template is a JSON file that describes all the resources/relations/variables/etc for particular logical entity.
CloudFormation can manage all the aspects/services of AWS. 

When template is pushed to AWS, CloudFormation will take it and will start creating resources and building relations between them.

Then (if template describes instances) it will spin instances up and execute corresponding UserData script on each of them.
UserData script, in turn, will perform pre-Chef magic (install and configure git, clone the repo to the server; install Chef, librarian, whatever else is necessary; install community cookbooks and dependencies (via librarian); lookup other instances, and finally launch Chef to provision the node)

The last step of instance creation is a POST request to so-called "instance wait handle URL". 
If user data script was executed successfully, and instance status was confirmed with POST, CloudFormation will update creation status to "CREATE COMPLETE". 
This is when you can start playing with instances.
If something went wrong during creation - CFN status will be "CREATE FAILED".

### Supervisor

Supervisor is a Docker-based image that contains all the necessary software to manage nodes/resources in AWS. Everything is executed from within the supervisor. [This readme](supervisor/README.md) explains how to use it.

Once you are inside of the supervisor image, the `minotaur.py` script may be used to provision an environment and labs. The rest of this readme assumes that the script is executed from within the supervisor container.

### Minotaur Commands

#### List Infrastructure Components
```
root@supervisor:/deploy# ./minotaur.py infrastructure list
Available deployments are: ['bastion', 'iampolicies', 'iamusertogroupadditions', 'nat', 'sns', 'subnet', 'vpc']
```
### Print Infrastructure Component Usage
```
root@supervisor:/deploy# ./minotaur.py infrastructure deploy bastion -h
usage: minotaur.py infrastructure deploy bastion [-h] -e ENVIRONMENT -r REGION
                                                 -z AVAILABILITY_ZONE
                                                 [-i INSTANCE_TYPE]

optional arguments:
  -h, --help            show this help message and exit
  -e ENVIRONMENT, --environment ENVIRONMENT
                        CloudFormation environment to deploy to
  -r REGION, --region REGION
                        Geographic area to deploy to
  -z AVAILABILITY_ZONE, --availability-zone AVAILABILITY_ZONE
                        Isolated location to deploy to
  -i INSTANCE_TYPE, --instance-type INSTANCE_TYPE
                        AWS EC2 instance type to deploy
```

#### Deploy Infrastructure Component

In this example, the `bdoss-dev` bastion already existed, so the CloudFormation stack was updated with the current template.
```
root@supervisor:/deploy# ./minotaur.py infrastructure deploy bastion -e bdoss-dev -r us-east-1 -z -us-east-1a
Template successfully validated.
Updating existing 'bastion-bdoss-dev-us-east-1-us-east-1a' stack...
Stack updated.
```

#### List Labs
List all supported labs.
```
root@supervisor:/deploy# ./minotaur.py lab list
Available deployments are: ['clouderahadoop', 'gokafkaconsumer', 'gokafkaproducer', 'kafka', 'mesosmaster', 'mesosslave', 'zookeeper']
```

#### Print Lab Usage
Print the kafka lab usage.
```
root@supervisor:/deploy# ./minotaur.py lab deploy kafka -h
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

#### Deploy Lab
Deploy a 3-broker Kafka cluster.
```
root@supervisor:/deploy# ./minotaur.py lab deploy kafka -e bdoss-dev -d kafka-example -r us-east-1 -z us-east-1a -n 3 -i m1.small    
Template successfully validated.
Creating new 'kafka-bdoss-dev-kafka-example-us-east-1-us-east-1a' stack...
Stack deployed.
```