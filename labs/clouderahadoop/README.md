clouderahadoop
==============

This directory contains AWS templates, Chef recipes and Vagrant VM example for a Highly-Available (HA) deployment of Cloudera Hadoop Distributed Filesystem (HDFS).

## Vagrant

### Topology

The vagrant example provisions the following topology, with each node being it's own virtual machine:

* 3 Zookeeper Servers
* 2 Hadoop Namenodes
* 3 Hadoop Journalnodes
* 1 Hadoop Resource Manager
* 2 Hadoop Datanodes

### Install Omnibus

Before provisioning the machines, please install the Vagrant Omnibus plugin:
```bash
vagrant plugin install vagrant-omnibus
```

Then, `up` all machines with `--no-provision` option:
```bash
vagrant up --no-provision
```

After all machines will be up and running, it is very important to provision them in parallel - otherwise they will fail. Following is a quick one-liner which will provision machines in parallel.

```bash
vagrant status | awk -F' '  '/virtualbox/ {print $1}' | xargs -n 1 -P 8 vagrant provision
```

## AWS

```
usage: minotaur lab deploy clouderahadoop {namenode,journalnode,datanode,resourcemanager}
```

```
usage: minotaur lab deploy clouderahadoop namenode [-h] -e ENVIRONMENT -d DEPLOYMENT
                                                   -r REGION -z AVAILABILITY_ZONE
                                                   [-n NUM_NODES] [-i INSTANCE_TYPE]

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

```

**Mandatory arguments:**

`<environment>` - name of the CloudFormation environment.

`<deployment>` - this term/option is used to logically separate groups of nodes within environment. Nodes that belong to different deployments won't interact with each other.

`<region>` - geographic area to deploy to.

`<availability zone>` - isolated location to deploy to.

**Optional arguments:**

`[number of nodes]` defaults to 1

`[instances flavor]` defaults to m1.small

**Example:**

`minotaur lab deploy clouderahadoop datanode -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -i m1.small` - this will spin up mesos master (v. 0.20.0) node in "testing" deployment.

`minotaur lab deploy clouderahadoop namenode -e bdoss-dev -d testing -r us-east-1 -z us-east-1a -n 3 -i m1.medium` - this will spin up 3 m1.medium mesos slave nodes in "testing" deployment.

*NOTICE:* If you're deploying a cluster - make sure that a separate Zookeeper node is running in the same environment and deployment.

During spin-up procedure, each Hadoop node will try to reveal all Zookeeper nodes running in the same environment+deployment and will configure itself against them.

All nodes must be push simultaneously to CFN, I'd recommend the following set of commands to be executed in a row.

```bash
minotaur lab deploy clouderahadoop journalnode -e bdoss-dev -d test -r us-east-1 -z us-east-1a -n 3
minotaur lab deploy clouderahadoop namenode -e bdoss-dev -d test -r us-east-1 -z us-east-1a -n 2
minotaur lab deploy clouderahadoop resourcemanager -e bdoss-dev -d test -r us-east-1 -z us-east-1a
minotaur lab deploy clouderahadoop datanode -e bdoss-dev -d test -r us-east-1 -z us-east-1a
```

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.