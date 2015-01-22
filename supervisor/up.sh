#!/bin/bash
#
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

CONTAINER_NAME="supervisor"

# Handle container start on ssh in Vagrant
SUPERVISOR_PATH="."
if [[ $(whoami) = "vagrant" ]]; then
SUPERVISOR_PATH="/deploy/supervisor"
cd $SUPERVISOR_PATH
fi

echo "Building ..."
docker build -t $CONTAINER_NAME $SUPERVISOR_PATH

echo "Spawning ..."
docker run -e "USER"=$1 --dns="127.0.0.1" --dns-search="aws" --name $CONTAINER_NAME -h supervisor -i -t -v $(pwd)/../:/deploy:ro supervisor /sbin/my_init -- bash -l

echo "Cleaning-up ..."
docker rm -f $CONTAINER_NAME
