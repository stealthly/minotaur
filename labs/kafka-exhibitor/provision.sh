#!/bin/bash -Eu

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
