##Zookeeper nodes

- clone this repo to **repo_dir**
- cd to **repo_dir/zookeeper/aws folder**
- exec **apply-zookeeper.sh**:

```
./apply-zookeeper.sh <environment> <deployment> <region> <availability zone> [number of nodes] [instances flavor] [zookeeper version]
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

`./apply-zookeeper.sh bdoss-dev testing us-east-1 us-east-1a 3` - this will spin up 3 zookeeper nodes in "testing" deployment.

NOTICE: All Zookeeper nodes that belong to the same deployment will form a cluster.

If you want to remove your deployment - just delete a corresponding CloudFormation stack in AWS Web Console.