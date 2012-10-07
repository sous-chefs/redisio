#
# Cookbook Name:: redisio
# Recipe:: slave
#
# Copyright 2012, Erik Kristensen <erik@erikkristensen.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
master = search(:node, "chef_environment:#{node.chef_environment} AND recipes:redisio\\:\\:master")

node['redisio']['servers'][0] = {'port' => node.redisio.servers.first['port'], 'slaveof' => {'address' => master.first['fqdn']}}

include_recipe "redisio::install"