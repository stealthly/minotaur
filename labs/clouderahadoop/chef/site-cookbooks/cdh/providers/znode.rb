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

# -*- mode: ruby -*-
# vi: set ft=ruby :

# This is a DSL wrapper around creating and getting
# znodes and their content on zookeeper server
require 'zookeeper'

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } already exists - nothing to do."
  else
    @current_resource.z.create(:path => "#{@new_resource.znode}")
    new_resource.updated_by_last_action(true)
    Chef::Log.info "Create #{ @new_resource }"
  end
end

action :delete do
  if @current_resource.exists
    @current_resource.z.delete(:path => "#{@new_resource.znode}")
    new_resource.updated_by_last_action(true)
    Chef::Log.info "Delete #{ @new_resource }"
  else
    Chef::Log.info "#{ @current_resource } doesn't exist - can't delete."
  end
end

action :set do
  if @current_resource.exists
    @current_resource.z.set(:path => "#{@new_resource.znode}", :data => "#{@new_resource.content}")
    new_resource.updated_by_last_action(true)
    Chef::Log.info "Content of #{ @new_resource } set to #{ @new_resource.content }"
  else
    Chef::Log.info ("Failed to set content of #{ @new_resource } to #{ @new_resource.content }")
    fail
  end
end

action :get do
  znode_content = @current_resource.z.get(:path => "#{@new_resource.znode}")[:data]
  unless znode_content.to_s.empty?
    Chef::Log.info ("Got content #{znode_content} for znode #{@new_resource.znode}")
    if @new_resource.content.to_s.empty? or @new_resource.content.to_s == znode_content.to_s
      @new_resource.destination.update( {"content" => "#{znode_content}"} )
      Chef::Log.info ("#{@new_resource.destination['content']}")
    else
      Chef::Log.info ("Expecting content: #{content}, got: #{znode_content}")
    end
  else fail
  end
end

action :get_children do
  children = @current_resource.z.get_children(:path => "#{@new_resource.znode}")[:children]
  if not children.to_s.empty?
    Chef::Log.info ("Got children #{children} for znode #{@new_resource.znode}")
    for item in children
      @new_resource.destination.update( {"#{item}" => true} )
    end
  else fail
  end
end

action :expect do
  znode_content = @current_resource.z.get(:path => "#{@new_resource.znode}")[:data]
  unless znode_content.to_s.empty?
    if @new_resource.content.to_s == znode_content.to_s
      Chef::Log.info ("Got content #{znode_content} for znode #{@new_resource.znode}")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info ("Expecting content: #{@new_resource.content}, got: #{znode_content}")
    end
  else fail
  end
end

def znode_exists?(znode)
  return @current_resource.z.get(:path => "#{znode}")[:stat].exists
end

def load_current_resource
  @current_resource = Chef::Resource::CdhZnode.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.server(@new_resource.server || node[:hadoop][:zk_servers][:ips].sample)
  @current_resource.znode(@new_resource.znode)
  @current_resource.destination(@new_resource.destination)
  @current_resource.content(@new_resource.content)
  @current_resource.expect(@new_resource.expect)
  @current_resource.z = Zookeeper.new("#{@current_resource.server}:2181")
  if znode_exists?(@current_resource.name)
    @current_resource.exists = true
  end
end
