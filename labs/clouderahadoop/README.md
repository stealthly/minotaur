clouderahadoop
==============

This directory contains Chef recipes and Vagrant VM example for a Highly-Available (HA) deployment of Cloudera Hadoop Distributed Filesystem (HDFS).

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

Then, simply say `up`:
```bash
vagrant up
```