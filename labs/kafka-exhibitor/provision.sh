#!/bin/bash -Eu

kafka_version=0.8.2.1

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

apt-get update
apt-get install -y default-jdk zookeeperd unzip

# Install Gradle v2.3
cd /opt
curl -O https://downloads.gradle.org/distributions/gradle-2.3-bin.zip
unzip gradle-2.3-bin.zip && rm gradle-2.3-bin.zip
ln -s gradle-2.3 gradle
export PATH=$PATH:/opt/gradle/bin

# Install latest version of Exhibitor
mkdir -p /opt/exhibitor
cd /opt/exhibitor
curl -O https://raw.githubusercontent.com/Netflix/exhibitor/master/exhibitor-standalone/src/main/resources/buildscripts/standalone/gradle/build.gradle
gradle shadowJar

# Install latest version of Kafka
cd /opt
curl -O https://dist.apache.org/repos/dist/release/kafka/$kafka_version/kafka_2.11-$kafka_version.tgz
tar -xzf kafka_2.11-$kafka_version.tgz && rm kafka_2.11-$kafka_version.tgz
ln -s kafka_2.11-0.8.2.1 kafka
