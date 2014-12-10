kafka-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up Kafka-broker nodes.

##Kafka broker nodes

- clone this repo to **repo_dir**
- cd to **repo_dir/kafka-lab/aws folder**
- exec **apply-kafka-broker.sh**:

```
./apply-kafka-broker.sh <environment> <deployment> <region> <availability zone> [source url] [number of instances] [instances flavor] [zookeeper version]
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

`./apply-kafka-broker.sh bdoss-dev testing us-east-1 us-east-1a http://example.com/kafka.tar.gz 3 m1.small` - this will spin up 3 kafka-broker nodes in "testing" deployment.

NOTICE: If you're deploying a cluster - make sure that a separate Zookeeper node is running in the same environment and deployment.

During spin-up procedure, each Kafka node will try to reveal all Zookeeper nodes running in the same environment+deployment and will configure itself against them.

If no Zookeeper(s) found - each Kafka node will install Zookeeper locally and will rely on it.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.