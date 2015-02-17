mesos-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up Mesos master and slave nodes.

## Usage
```
usage: minotaur lab deploy mesos master [-h] [--debug] [--mesos-dns] -e ENVIRONMENT -d
                                        DEPLOYMENT -r REGION -z AVAILABILITY_ZONE -o
                                        HOSTED_ZONE [-n NUM_NODES] [-i INSTANCE_TYPE]
                                        [-m MESOS_VERSION] [-v ZK_VERSION] [-a AURORA_URL]
                                        [-t MARATHON_VERSION] [--marathon] [--aurora]
                                        [--slave-on-master]

optional arguments:
  -h, --help            show this help message and exit
  --debug               Enable debug mode
  --mesos-dns           Use this flag to deploy Mesos-DNS on Marathon
  -e ENVIRONMENT, --environment ENVIRONMENT
                        CloudFormation environment to deploy to
  -d DEPLOYMENT, --deployment DEPLOYMENT
                        Unique name for the deployment
  -r REGION, --region REGION
                        Geographic area to deploy to
  -z AVAILABILITY_ZONE, --availability-zone AVAILABILITY_ZONE
                        Isolated location to deploy to
  -o HOSTED_ZONE, --hosted-zone HOSTED_ZONE
                        The name of dns route53 hosted zone
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
  -t MARATHON_VERSION, --marathon-version MARATHON_VERSION
                        The Marathon version to deploy
  --marathon            Use this flag to deploy Marathon framework
  --aurora              Use this flag to deploy Aurora framework
  --slave-on-master     Use this flag to deploy Mesos slaves on master nodes
```

```
usage: minotaur lab deploy mesos slave [-h] [--debug] [--mesos-dns] -e ENVIRONMENT -d
                                       DEPLOYMENT -r REGION -z AVAILABILITY_ZONE -o HOSTED_ZONE
                                       [-n NUM_NODES] [-i INSTANCE_TYPE] [-m MESOS_VERSION]
                                       [-v ZK_VERSION]

optional arguments:
  -h, --help            show this help message and exit
  --debug               Enable debug mode
  --mesos-dns           Use this flag to deploy Mesos-DNS on Marathon
  -e ENVIRONMENT, --environment ENVIRONMENT
                        CloudFormation environment to deploy to
  -d DEPLOYMENT, --deployment DEPLOYMENT
                        Unique name for the deployment
  -r REGION, --region REGION
                        Geographic area to deploy to
  -z AVAILABILITY_ZONE, --availability-zone AVAILABILITY_ZONE
                        Isolated location to deploy to
  -o HOSTED_ZONE, --hosted-zone HOSTED_ZONE
                        The name of dns route53 hosted zone
  -n NUM_NODES, --num-nodes NUM_NODES
                        Number of instances to deploy
  -i INSTANCE_TYPE, --instance-type INSTANCE_TYPE
                        AWS EC2 instance type to deploy
  -m MESOS_VERSION, --mesos-version MESOS_VERSION
                        The Mesos version to deploy
  -v ZK_VERSION, --zk-version ZK_VERSION
                        The Zookeeper version to deploy
```

**Mandatory arguments:**

`<environment>` - name of the CloudFormation environment.

`<deployment>` - this term/option is used to logically separate groups of nodes within environment. Nodes that belong to different deployments won't interact with each other.

`<region>` - geographic area to deploy to.

`<availability zone>` - isolated location to deploy to.

`<hosted zone>` - name of hosted zone registered in aws route53 which will be used to associate dns names to mesos nodes.

**Optional arguments:**

`[number of nodes]` defaults to 1

`[instances flavor]` defaults to m1.small

`[mesos version]` defaults to 0.21.0

`[zookeeper version]` defaults to 3.4.6

`[marathon version]` defaults to 0.7.5

`[modules]` defaults to marathon

`[aurora url]` defaults to https://s3.amazonaws.com/bdoss-deploy/mesos/aurora/aurora-scheduler-0.6.1.tar

**Example:**

`minotaur lab deploy mesos master -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -o bdoss.org -m 0.20.0 -i m1.small --marathon --aurora` - this will spin up mesos master (v. 0.20.0) node with marathon (v. 0.7.5) and aurora in "testing" deployment.

`minotaur lab deploy mesos master -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -o bdoss.org -m 0.21.0 -i m1.small -n 3 --marathon --mesos-dns --slave-on-master` - this will spin up three mesos master (v. 0.21.0) nodes with marathon (v. 0.7.5) in "testing" deployment, run mesos slave on every master node, run mesos dns and install it as default nameserver on every node.

`minotaur lab deploy mesos slave -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -o bdoss.org -n 3 -i m1.medium` - this will spin up 3 m1.medium mesos slave nodes in "testing" deployment.

*NOTICE:* If you're deploying a cluster - make sure that a separate Zookeeper node is running in the same environment and deployment.

During spin-up procedure, each Mesos node (this also applies to master) will try to reveal all Zookeeper nodes running in the same environment+deployment and will configure itself against them.

If no Zookeeper(s) found - Mesos master will install Zookeeper locally and will rely on it, slaves will configure themselves to use zookeeper on master node.

After pushing master node to CFN, I'd recommend waiting a minute or two before pushing slaves, just to make sure master instance is ready before slaves connect to it.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.

*NOTICE:* DNS entries in aws route53 will STAY there even after stack termination, so be sure to delete them manually using aws cli or aws route53 web ui after stack termination.