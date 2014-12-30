supervisor
=========
Supervisor is a Docker-based image that contains all the necessary software to manage nodes/resources in AWS.

###Supervisor set-up

- clone this repo to **repo_dir**
- cd to **repo_dir/supervisor** folder

Before trying to build docker image, you must put some configuration files under **config** directory:

a) **aws_config**

This file is just a regular aws-cli config, you must paste your secret and access keys, provided by Amazon in it:

```
[default]
output = json
region = us-east-1
aws_access_key_id = SECRET_KEY
aws_secret_access_key = ACCESS_KEY
```

Do not add or remove any extra whitespaces (especially before and after "=" sign in keys)

b) **private.key**

This is your private SSH key, public part of which is registered on Bastion host

c) **ENVIRONMENT.key**

This is a shared key for all nodes in environment ENVIRONMENT Supervisor is supposed to manage (e.g bdoss-dev.key for bdoss-dev environment, etc.).

- exec **up.sh**:

Supervisor depends on docker version >= 1.3.0.

If this is the first time you're launching supervisor - it will take some time to build.

Subsequent up's will take seconds.

### Using supervisor

Now you can cd to /deploy/labs/ and deploy whatever you want


**Example:**

```
root@supervisor:/deploy# minotaur lab deploy mesosmaster -e bdoss-dev -d test -r us-east-1 -z us-east-1a
Template successfully validated.
Creating new stack 'mesos-master-test-bdoss-dev-us-east-1-us-east-1a'...
Stack deployed.
```

this will spin up a mesos master node in "test" deployment.

** Local DNS Names **
Supervisor has internal local dns system. It uses SkyDNS with etcd backend. DNS records are populated every minute using cron job, so be patient and give it a little time(up to a minute) right after container run to populate everything properly. Right after that you can get instances local DNS names using `awsinfo` command.

**awsinfo**

Supervisor has a built-in "awsinfo" command, which relies on AWS API and provides brief info about running machines.
It is also capable of searching through that info.

**Usage example**

`awsinfo` - will display brief info about all nodes running in AWS

```
root@supervisor:/deploy# awsinfo
Cloud:  bdoss/us-east-1
Name                                Instance ID  Instance Type  Instance State  Private IP      Public IP      Local DNS Name
----                                -----------  -------------  --------------  ----------      ---------      --------------
nat.bdoss-dev                       i-c46a0b2a   m1.small       running         10.0.2.94       54.86.153.142  ip-10-0-2-94.bdoss-dev.aws
bastion.bdoss-dev                   i-3faa69de   m1.small       running         10.0.0.207      None           ip-10-0-0-270.bdoss-dev.aws
mesos-master.test.bdoss-dev         i-e80ddc09   m1.small       terminated      None            None           unknown
mesos-slave.test.bdoss-dev          i-e00ddc01   m1.small       terminated      None            None           unknown
```

`awsinfo mesos-master` - will display info about all mesos-master nodes running in AWS.

```
root@supervisor:/deploy/labs# awsinfo mesos-master
Cloud:  bdoss/us-east-1
Name                                Instance ID  Instance Type  Instance State  Private IP      Public IP      Local DNS Name
----                                -----------  -------------  --------------  ----------      ---------      --------------
mesos-master.test.bdoss-dev         i-e80ddc09   m1.small       terminated      None            None           unknown
```

`awsinfo 10.0.2` - match a private/public subnet

```
root@supervisor:/deploy/labs# awsinfo 10.0.2
Cloud:  bdoss/us-east-1
Name                                Instance ID  Instance Type  Instance State  Private IP      Public IP      Local DNS Name
----                                -----------  -------------  --------------  ----------      ---------      --------------
nat.bdoss-dev                       i-c46a0b2a   m1.small       running         10.0.2.94       54.86.153.142  ip-10-0-2-94.bdoss-dev.aws
mesos-master.test.bdoss-dev         i-e96ebd08   m1.small       running         10.0.2.170      54.172.160.254 ip-10-0-2-170.bdoss-dev.aws
```

## Vagrant

If you can't use Docker directly for some reason, there's a Vagrant wrapper VM for it.

Before doing anything with Vagrant, complete the above steps for Docker, but don't execute up.sh script

Just cd into vagrant directory and exec `vagrant up`, then `vagrant ssh` (nothing special here yet).

When you will exec `vagrant ssh`, docker container build process will spawn up immediately, so wait a bit and let it complete.

Now you're inside a Docker container nested in Vagrant VM and can proceed with deployment in the same manner as it's described for docker.

All the following `vagrant ssh`'s will spawn Docker container almost immediately.
