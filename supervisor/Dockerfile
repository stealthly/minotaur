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
# CMD ["/sbin/my_init"]

# Installing AWS-related stuff
RUN apt-get update
RUN apt-get install -y git-core python-boto python-pip curl
RUN pip install awscli
RUN pip install six==1.8.0
RUN curl https://stedolan.github.io/jq/download/linux64/jq -o /usr/local/bin/jq
RUN chmod +x /usr/local/bin/jq

# Configuring aws-cli
RUN mkdir -p /root/.aws
COPY config/aws_config /root/.aws/config

# Checking config
RUN AWS_ACCESS_KEY=$(grep aws_access_key_id /root/.aws/config | awk -F= '{print $2}') && \
if [ -z "$AWS_ACCESS_KEY" ]; then exit 1; fi
RUN AWS_SECRET_KEY=$(grep aws_secret_access_key /root/.aws/config | awk -F= '{print $2}') && \
if [ -z "$AWS_SECRET_KEY" ]; then exit 1; fi

# Copying info script and configuring it
RUN mkdir -p /root/.ssh
COPY . /root/
RUN ln -s /root/scripts/cgnaws/awsinfo.py /usr/local/bin/awsinfo
RUN ln -s /root/scripts/cgnaws/template_ssh.py /usr/local/bin/templatessh
# RUN chmod +x /usr/local/bin/awsinfo

# Link master script to bin directory
RUN ln -s /deploy/minotaur.py /usr/local/bin/minotaur

# Creating ssh config
COPY config/ssh_config /root/.ssh/config
COPY config/environment.key /root/.ssh/
COPY config/private.key /root/.ssh/
RUN chmod 600 /root/.ssh/config
RUN chmod 600 /root/.ssh/*.key

# Pre-creating deploy volume path
VOLUME ["/deploy"]

# Cleaning up APT when done
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /deploy
CMD ["/bin/bash"]
