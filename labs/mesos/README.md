mesos-lab
=========
This directory contains AWS, Chef and Vagrant scripts/recipes/templates to spin up Mesos master and slave nodes.

## Usage
```
usage: minotaur lab deploy mesos master [-h] [--debug] [--mesos-dns] [--gauntlet] [--spark] -e
                                        ENVIRONMENT -d DEPLOYMENT -r REGION -z
                                        AVAILABILITY_ZONE -o HOSTED_ZONE [-n NUM_NODES]
                                        [-i INSTANCE_TYPE] [-m MESOS_VERSION]
                                        [-v {3.3.6,3.4.6,3.5.0-alpha}] [-s SPARK_VERSION]
                                        [--spark-url SPARK_URL] [-a AURORA_URL]
                                        [-t MARATHON_VERSION] [--marathon] [--aurora]
                                        [--slave-on-master] [--chronos]

optional arguments:
  -h, --help            show this help message and exit
  --debug               Enable debug mode
  --mesos-dns           Use this flag to deploy Mesos-DNS on Marathon
  --gauntlet            Use this flag to deploy Gauntlet framework
  --spark               Use this flag to deploy Spark framework
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
  -v {3.3.6,3.4.6,3.5.0-alpha}, --zk-version {3.3.6,3.4.6,3.5.0-alpha}
                        The Zookeeper version to deploy
  -a AURORA_URL, --aurora-url AURORA_URL
                        The Aurora scheduler URL
  -t MARATHON_VERSION, --marathon-version MARATHON_VERSION
                        The Marathon version to deploy
  -s SPARK_VERSION, --spark-version SPARK_VERSION
                        The Spark version to deploy
  --spark-url SPARK_URL
                        URL of custom Spark binaries tarball
  --marathon            Use this flag to deploy Marathon framework
  --aurora              Use this flag to deploy Aurora framework
  --slave-on-master     Use this flag to deploy Mesos slaves on master nodes
  --chronos             Use this flag to deploy Chronos framework
```

```
usage: minotaur lab deploy mesos slave [-h] [--debug] [--mesos-dns] [--gauntlet] [--spark] -e
                                       ENVIRONMENT -d DEPLOYMENT -r REGION -z AVAILABILITY_ZONE
                                       -o HOSTED_ZONE [-n NUM_NODES] [-i INSTANCE_TYPE]
                                       [-m MESOS_VERSION] [-v {3.3.6,3.4.6,3.5.0-alpha}]
                                       [-s SPARK_VERSION] [--spark-url SPARK_URL]
                                       [--mirrormaker]

optional arguments:
  -h, --help            show this help message and exit
  --debug               Enable debug mode
  --mesos-dns           Use this flag to deploy Mesos-DNS on Marathon
  --gauntlet            Use this flag to deploy Gauntlet framework
  --spark               Use this flag to deploy Spark framework
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
  -v {3.3.6,3.4.6,3.5.0-alpha}, --zk-version {3.3.6,3.4.6,3.5.0-alpha}
                        The Zookeeper version to deploy
  -s SPARK_VERSION, --spark-version SPARK_VERSION
                        The Spark version to deploy
  --spark-url SPARK_URL
                        URL of custom Spark binaries tarball
  --mirrormaker         Use this flag to deploy Mirrormaker
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

`[aurora url]` defaults to https://s3.amazonaws.com/bdoss-deploy/mesos/aurora/aurora-scheduler-0.6.1.tar

`[spark version]` defaults to 1.2.1

`[spark url]` defaults to https://dist.apache.org/repos/dist/release/spark/spark-1.2.1/spark-1.2.1-bin-cdh4.tgz

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

*NOTICE:* Currently only corse mode is supported in spark framework on mesos.

## Kafka test framework labs deployment procedure (automated mode)

1. Deploy labs
  ```
  minotaur lab deploy cassandra -e bdoss-dev -d test -r us-east-1 -z us-east-1a
  minotaur lab deploy zookeeper -e bdoss-dev -d test -r us-east-1 -z us-east-1a
  minotaur lab deploy kafka -e bdoss-dev -d test -r us-east-1 -z us-east-1a
  ```

2. Wait untill zookeeper and kafka are deployed and deploy mesos master
  ```
  minotaur lab deploy mesos master --marathon --spark --gauntlet --chronos -e bdoss-dev -d test -r us-east-1 -z us-east-1a -o bdoss.org -i m1.small
  ```

3. Wait few minutes and deploy mesos slave
  ```
  minotaur lab deploy mesos slave --gauntlet --mirrormaker --spark -e bdoss-dev -d test -r us-east-1 -z us-east-1a -o bdoss.org -i m3.xlarge
  ```

This will spawn cassandra, zookeeper and kafka servers(topic "dataset" and "mirror_dataset" will be created in kafka too), spawn mesos master node with marathon (which will run kafka producer) and chronos (which will wait 10-15 minutes and then destroy kafka producer and run kafka test framework - gauntlet with mirror_maker as client.runner) frameworks and spawn mesos slave instance (m3.xlarge is the smallest one which can process generated data). After some time (up to 20 minutes after deployment will finish, you can access slave instance via ssh and check file with test results under /opt/gauntlet/ directory). Also you can access spark ui via http://master0.bdoss.org:4040 when kafka test framework will be running on a slave.

## Kafka test framework labs deployment procedure (manual mode)

1. Deploy labs
  ```
  minotaur lab deploy cassandra -e bdoss-dev -d test -r us-east-1 -z us-east-1a
  minotaur lab deploy zookeeper -e bdoss-dev -d test -r us-east-1 -z us-east-1a
  minotaur lab deploy kafka -e bdoss-dev -d test -r us-east-1 -z us-east-1a
  ```

2. Wait untill zookeeper and kafka are deployed and deploy mesos master
  ```
  minotaur lab deploy mesos master --marathon --spark --gauntlet -e bdoss-dev -d test -r us-east-1 -z us-east-1a -o bdoss.org -i m1.small
  ```

3. Wait few minutes and deploy mesos slave
  ```
  minotaur lab deploy mesos slave --gauntlet --mirrormaker -e bdoss-dev -d test -r us-east-1 -z us-east-1a -o bdoss.org -i m3.xlarge
  ```

*NOTICE:* The first two steps are optional - kafka topics will be created by default and kafka producer will be launched by default too. Follow the first two steps only if you want to use non-default topics or custom --client.runner.

1. Create topics in kafka: ssh into kafka instance and run the following, e.g.
  ```
  /opt/apache/kafka/bin/kafka-topics.sh --create --topic dataset --partitions 1 --replication-factor 1 --zookeeper $ZOOKEEPER_SERVER
  /opt/apache/kafka/bin/kafka-topics.sh --create --topic mirror_dataset --partitions 1 --replication-factor 1 --zookeeper $ZOOKEEPER_SERVER
  ```

2. Run kafka producer, generator and some custom client launch command: go to marathon web ui (e.g. master0.bdoss.org:8080) and create a new task with the following code in a command field

  `cd /opt/gauntlet && ./gradlew jar && ./run.sh --client.runner "mirror_maker --prefix mirror_ --consumer.config /tmp/consumer.config --num.streams 2 --producer.config /tmp/producer.config --whitelist=\"^dataset\""`

  or create a temporary json payload file(e.g. /tmp/run.json) with the following content
  ```
  {
    "id": "producer",
    "cmd": "cd /opt/gauntlet && ./gradlew jar && ./run.sh --client.runner \"mirror_maker --prefix mirror_ --consumer.config /tmp/consumer.config --num.streams 2 --producer.config /tmp/producer.config --whitelist=\\\"^dataset\\\"\"",
    "instances": 1,
    "cpus": 1,
    "mem": 1024
  }
  ```

  and post it to marathon
  `curl -X POST -H "Content-Type: application/json" http://${MESOS_MASTER}:8080/v2/apps -d@/tmp/run.json`

3. Run test framework: ssh to master instance and run the following, e.g.(Dont forget to change --executor-memory and --total-executor-cores settings in validate.sh). You will need at least 12G memory on slave and 4 cores to process it.
  ```
  cd /opt/gauntlet
  ./gradlew jar
  ./validate.sh --kafka.source.topic dataset --kafka.destination.topic mirror_dataset --kafka.fetch.size 64 --kafka.partitions 1 &
  ```
