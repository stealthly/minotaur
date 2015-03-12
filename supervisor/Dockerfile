# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Supervisor
#

FROM phusion/baseimage:latest
MAINTAINER Big Data Open Source Security LLC <info@stealth.ly>

# Setting correct environment variables
ENV HOME /root

# Regenerating SSH host keys
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Using baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Installing AWS-related stuff
RUN apt-get update
RUN apt-get install -y git-core python-boto python-pip curl dnsutils
RUN pip install awscli
RUN pip install six==1.8.0
RUN curl https://stedolan.github.io/jq/download/linux64/jq -o /usr/local/bin/jq
RUN chmod +x /usr/local/bin/jq

# Configuring aws-cli
RUN mkdir -p /root/.aws
COPY config/aws_config /root/.aws/config
COPY config/aws_config /root/.boto
RUN sed -i 's/default/Credentials/' /root/.boto

# Checking config
RUN AWS_ACCESS_KEY=$(grep aws_access_key_id /root/.aws/config | awk -F= '{print $2}') && \
if [ -z "$AWS_ACCESS_KEY" ]; then exit 1; fi
RUN AWS_SECRET_KEY=$(grep aws_secret_access_key /root/.aws/config | awk -F= '{print $2}') && \
if [ -z "$AWS_SECRET_KEY" ]; then exit 1; fi

# Creating ssh config
#RUN touch /root/.ssh/config
COPY config/*.key /root/.ssh/
#RUN chmod 600 /root/.ssh/config
RUN chmod 600 /root/.ssh/*.key

# Installing etcd and skydns
RUN aws s3 cp s3://bdoss-deploy/utils/skydns/skydns /root/bin/skydns
RUN aws s3 cp s3://bdoss-deploy/utils/etcd/etcd /root/bin/etcd
RUN aws s3 cp s3://bdoss-deploy/utils/etcd/etcdctl /root/bin/etcdctl
RUN chmod 744 /root/bin/skydns
RUN chmod 744 /root/bin/etcd
RUN chmod 744 /root/bin/etcdctl
RUN ln -s /root/bin/skydns /usr/local/bin/skydns
RUN ln -s /root/bin/etcd /usr/local/bin/etcd
RUN ln -s /root/bin/etcdctl /usr/local/bin/etcdctl

# Preparing daemon scripts
RUN mkdir /etc/service/etcd
RUN mkdir /etc/service/skydns
RUN mkdir /usr/local/bin/default.etcd
RUN echo "#!/bin/sh\nexec /usr/local/bin/etcd -data-dir /usr/local/bin/default.etcd >>/var/log/etcd.log 2>&1" > /etc/service/etcd/run
RUN echo "#!/bin/sh\nif ps aux | grep /etcd | grep -v grep > /dev/null\n  then\n    sleep 10\n    \
exec /usr/local/bin/skydns -verbose -addr="127.0.0.1:53" -nameservers="8.8.8.8:53,8.8.4.4:53" \
-machines="http://127.0.0.1:4001" -domain="aws." >>/var/log/skydns.log 2>&1\nfi" > /etc/service/skydns/run
RUN chmod 744 /etc/service/etcd/run
RUN chmod 744 /etc/service/skydns/run

# Setting crontab
RUN echo "* * * * * root python /deploy/supervisor/scripts/cgnaws/update_dns.py >> /var/log/cron.log 2>&1" >> /etc/crontab
RUN touch /var/log/cron.log

# Copying info script and configuring it
RUN mkdir -p /root/.ssh
COPY . /root/
RUN ln -s /root/scripts/cgnaws/awsinfo.py /usr/local/bin/awsinfo
RUN ln -s /root/scripts/cgnaws/template_ssh.py /usr/local/bin/templatessh
# RUN chmod +x /usr/local/bin/awsinfo

# Link master script to bin directory
RUN ln -s /deploy/minotaur.py /usr/local/bin/minotaur

# Pre-creating deploy volume path
VOLUME ["/deploy"]

# Cleaning up APT when done
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setting up ntp
RUN apt-get update
RUN apt-get install -y ntp
RUN /usr/sbin/ntpdate 0.ubuntu.pool.ntp.org && service ntp start

# Turn off syslog-to-docker-logs forwarder
RUN touch /etc/service/syslog-forwarder/down

WORKDIR /deploy
