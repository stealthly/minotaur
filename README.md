Minotaur
========

This repo contains scripts/recipes/configs to spin up VPC-based infrastructure in AWS from scratch and deploy labs to it.

###Getting started with AWS
Before actually spinning instances up or managing infrastructure, you'll need:

- aws-cli tools installed and configured with your credentials
- jq tool (https://stedolan.github.io/jq/)
- IAM permissions to use CloudFormation

Alternatively, you can use Supervisor image to manage AWS-related stuff.

Optionally you might also want to register your account on Bastion, to have SSH access to instances. 
Info about how to do it can be found in [README](infrastructure/aws/bastion).

First of all, fork this repo and populate your users folder like it is told in Bastion readme. Don't forget to specify your repository url while deploying bastion.

Don't forget to deploy infrastructure before starting to deploy labs, otherwise they will have no place to live in.

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

Before using minotaur script you must explicitly create or upload precreated key pair to aws ec2. A name of this key pair must be equal to the name of environment you want to create. Lately you will use this key with a key you specified in bastion [users folder](infrastructure/aws/bastion/chef/data_bags/users) to ssh into your instances.

### Minotaur Commands

#### List Infrastructure Components
```
root@supervisor:~# minotaur infrastructure list
Available deployments are: ['bastion', 'iampolicies', 'iamusertogroupadditions', 'nat', 'sns', 'subnet', 'vpc']
```
#### Print Infrastructure Component Usage
```
root@supervisor:~# minotaur infrastructure deploy bastion -h
usage: minotaur infrastructure deploy bastion [-h] -e ENVIRONMENT -r REGION -z
                                              AVAILABILITY_ZONE
                                              [-i INSTANCE_TYPE] [-u REPO_URL]

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
  -u REPO_URL, --repo-url REPO_URL
                        Public repository url where user info is stored
```

#### Deploy Infrastructure Component

In this example, the `bdoss-dev` bastion already existed, so the CloudFormation stack was updated with the current template.
```
root@supervisor:~# minotaur infrastructure deploy bastion -e bdoss-dev -r us-east-1 -z -us-east-1a
Template successfully validated.
Updating existing 'bastion-bdoss-dev-us-east-1-us-east-1a' stack...
Stack updated.
```

#### Deploy All Infrastructure Components
Deploy all infrastructure components one after another. In approximately 12 minutes infrastructure will be up and running.
```
root@supervisor:/deploy# minotaur infrastructure deploy all -e bdoss-dev -r us-east-1 -z us-east-1a -i m1.small -c 10.0.8.0/21
Template successfully validated.
Creating new 'sns-cloudformation-notifications-bdoss-dev-us-east-1' stack...
Stack created.
Template successfully validated.
Creating new 'sns-autoscaling-notifications-bdoss-dev-us-east-1' stack...
........................................................................
Template successfully validated.
Creating new  'bastion-bdoss-dev-us-east-1-us-east-1a' stack...
Stack created.
```
Notice that this will not deploy iam policies and iam user to group additions, so you must do it explicitly.
You can easily add users to specific security group in [iam user to group additions](infrastructure/aws/iamusertogroupadditions/aws/template.cfn) cloudformation template(default user there is admin)

Recommended subnetting scheme is as follows: for each vpc of, for example, 10.0.0.0/21 there is 2 public 10.0.0.0/23, 10.0.0.4/23 subnets, 2 private 10.0.0.2/24, 10.0.0.6/24 subnets and 2 reserved 10.0.0.3/24, 10.0.0.7/24 subnets. So there is 3 subnets(public, private and reserved) per one availability zone.
```
root@supervisor:/deploy# minotaur infrastructure deploy iampolicies
Template successfully validated.
Creating new 'iam-policies' stack...
Stack created.
root@supervisor:/deploy# minotaur infrastructure deploy iamusertogroupadditions
Template successfully validated.
Creating new  'iam-user-to-group-additions' stack...
Stack created.
```

#### List Labs
List all supported labs.
```
root@supervisor:~# minotaur lab list
Available deployments are: ['clouderahadoop', 'gokafkaconsumer', 'gokafkaproducer', 'kafka', 'mesosmaster', 'mesosslave', 'zookeeper']
```

#### Print Lab Usage
Print the kafka lab usage.
```
root@supervisor:~# minotaur lab deploy kafka -h
usage: minotaur lab deploy kafka [-h] -e ENVIRONMENT -d DEPLOYMENT -r REGION
                                 -z AVAILABILITY_ZONE [-n NUM_NODES]
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
root@supervisor:~# minotaur lab deploy kafka -e bdoss-dev -d example -r us-east-1 -z us-east-1a -n 3 -i m1.small
Template successfully validated.
Creating new 'kafka-bdoss-dev-example-us-east-1-us-east-1a' stack...
Stack deployed.
```

#### SSH In To The Instance
Before you will actually ssh you must run `templatessh` script to populate ssh config. Don't forget to reuse it every time you create a new environment.

Now you can log in to the instances simply by typing:
```
ssh ip-10-0-X-X.ENVIRONMENT.aws
```

#### Local DNS Names
Supervisor has internal local dns system. It uses SkyDNS with etcd backend. DNS records are populated every minute using cron job, so be patient and give it a little time(up to a minute) right after container run to populate everything properly. Right after that you can find local DNS names of instances using `awsinfo` command.

#### Relevant readme's

Look into [Supervisor README](supervisor/README.md) to learn more about supervisor docker container and files required to run it.

Look into [Bastion README](infrastructure/aws/bastion/README.md) to learn more about user credentials for ssh access.