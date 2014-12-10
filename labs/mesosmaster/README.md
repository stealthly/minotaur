mesos-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up Mesos master and slave nodes.

##Mesos nodes

- clone this repo to **repo_dir**
- cd to **repo_dir/mesos-lab/aws folder**
- exec **apply-mesos-master.sh**:

```
./apply-mesos-master.sh <environment> <deployment> <region> <availability zone> [number of nodes] [instances flavor] [aurora url] [mesos version] [zookeeper version]
```

- exec **apply-mesos-slave.sh**:

```
./apply-mesos-slave.sh <environment> <deployment> <region> <availability zone> [number of nodes] [instances flavor] [mesos version] [zookeeper version]
```

**Mandatory arguments:**

`<environment>` - currently we have only **bdoss-dev** environment in VPC, use it

`<deployment>` - this term/option is used to logically separate groups of nodes within environment. Nodes that belong to different deployments won't interact with each other.

`<region>` - VPC is currently deployed in **us-east-1** region

`<availability zone>` - bdoss-dev environment belongs to **us-east-1a** availability zone

**Optional arguments:**

`[number of nodes]` defaults to 1

`[instances flavor]` defaults to m1.small

`[aurora url]` defaults to https://s3.amazonaws.com/bdoss-deploy/mesos/aurora/aurora-scheduler-0.6.1.tar

`[mesos version]` defaults to 0.20.1

`[zookeeper version]` defaults to 3.4.6

**Example:**

`./apply-mesos-master.sh bdoss-dev testing us-east-1 us-east-1a 0.20.0 m1.small` - this will spin up mesos master (v. 0.20.0) node in "testing" deployment.

`./apply-mesos-master.sh bdoss-dev testing us-east-1 us-east-1a 3 m1.medium` - this will spin up 3 m1.medium mesos slave nodes in "testing" deployment.

NOTICE: If you're deploying a cluster - make sure that a separate Zookeeper node is running in the same environment and deployment.

During spin-up procedure, each Mesos node (this also applies to master) will try to reveal all Zookeeper nodes running in the same environment+deployment and will configure itself against them.

If no Zookeeper(s) found - Mesos master will install Zookeeper locally and will rely on it, slaves will configure themselves to use zookeeper on master node.

After pushing master node to CFN, I'd recommend waiting a minute or two before pushing slaves, just to make sure master instance is ready before slaves connect to it.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.