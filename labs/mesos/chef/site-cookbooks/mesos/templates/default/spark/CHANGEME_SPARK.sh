# Deploy labs
minotaur lab deploy kafka -e bdoss-dev -d dev -r us-east-1 -z us-east-1a
minotaur lab deploy zookeeper -e bdoss-dev -d dev -r us-east-1 -z us-east-1a
minotaur lab deploy cassandra -e bdoss-dev -d dev -r us-east-1 -z us-east-1a -i m1.small -n 1

minotaur lab deploy mesos master --mesos-dns -e bdoss-dev -d dev -r us-east-1 -z us-east-1a --marathon -o bdoss.net -i m1.medium
minotaur lab deploy mesos slave --mesos-dns -e bdoss-dev -d dev -r us-east-1 -z us-east-1a -o bdoss.net -i m1.medium

# At cassandra host(don't need this no more)
echo -e "rpc_address: 10.0.0.184" >> /etc/cassandra/cassandra.yaml
service cassandra restart

# On mesos-slave
cd /opt
git clone https://github.com/stealthly/gauntlet
chmod +x /opt/gauntlet/run.sh
# Change run.sh file with needed ips
vi /opt/gauntlet/run.sh

# Find zookeeper, kafka and cassandra nodes that belong to the same deployment and environment
export DEPLOYMENT=dev
export ENVIRONMENT=bdoss-dev
NODES_FILTER="Name=tag:Name,Values=zookeeper.$DEPLOYMENT.$ENVIRONMENT"
QUERY="Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress"
export ZK_SERVERS=$(aws ec2 describe-instances --region "$REGION" --filters "$NODES_FILTER" --query "$QUERY" | jq --raw-output 'join(",")')
NODES_FILTER="Name=tag:Name,Values=cassandra.$DEPLOYMENT.$ENVIRONMENT"
export CASSANDRA_SERVERS=$(aws ec2 describe-instances --region "$REGION" --filters "$NODES_FILTER" --query "$QUERY" | jq --raw-output 'join(",")')
NODES_FILTER="Name=tag:Name,Values=kafka.$DEPLOYMENT.$ENVIRONMENT"
export KAFKA_SERVERS=$(aws ec2 describe-instances --region "$REGION" --filters "$NODES_FILTER" --query "$QUERY" | jq --raw-output 'join(",")')

export REGION=us-east-1
aws s3 cp --region $REGION s3://bdoss-deploy/kafka/mirrormaker/mirror_maker /usr/local/bin/mirror_maker
chmod +x /usr/local/bin/mirror_maker
echo -e "zookeeper.connect=${ZK_SERVERS}:2181" > /tmp/consumer.config
echo -e "metadata.broker.list=${KAFKA_SERVERS}:9092\n\
timeout=10s" > /tmp/producer.config

aws s3 cp --region $REGION s3://bdoss-deploy/mesos/spark/spark-1.2.0-bin-1.0.4.tgz /tmp/spark-1.2.0-bin-1.0.4.tgz
#aws s3 cp --region $REGION s3://bdoss-deploy/mesos/spark/spark-1.2.0.tgz /tmp/spark-1.2.0.tgz
#mkdir /usr/local/spark
tar -xzf /tmp/spark-1.2.0-bin-1.0.4.tgz -C /opt
mv /opt/spark-1.2.0-bin-1.0.4 /opt/spark
#tar -xzf /tmp/spark-1.2.0.tgz -C /opt
#mv /opt/spark-1.2.0 /opt/spark
echo -e "export MASTER=mesos://zk://${ZK_SERVERS}:2181/mesos\n\
export MESOS_NATIVE_LIBRARY=/usr/local/lib/libmesos.so\n\
export SPARK_EXECUTOR_URI=http://d3kbcqa49mib13.cloudfront.net/spark-1.2.1-bin-hadoop2.4.tgz" > /opt/spark/conf/spark-env.sh
echo -e "spark.master mesos://zk://${ZK_SERVERS}:2181/mesos\n\
spark.executor.uri http://d3kbcqa49mib13.cloudfront.net/spark-1.2.1-bin-hadoop2.4.tgz\n\
spark.mesos.coarse true" > /opt/spark/conf/spark-defaults.conf
echo -e "metadata.broker.list=${KAFKA_SERVERS}:9092" >> /opt/gauntlet/producer.properties

cd /opt/gauntlet
./run.sh 1

# Testing spark-shell
# You need to build spark to run spark shell
/opt/spark/bin/spark-shell

sc.parallelize(1 to 1000).count()
