#
# Cookbook Name:: redisio
# Recipe:: sentinel
#
# Copyright 2013, Brian Bianco <brian.bianco@gmail.com>
# Copyright 2013, Rackspace Hosting <ryan.cleere@rackspace.com>
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
include_recipe 'redisio::_install_prereqs'
include_recipe 'redisio::install'
include_recipe 'ulimit::default'

redis = node['redisio']

sentinel_instances = redis['sentinels']
if sentinel_instances.empty?
  sentinel_instances = [{'port' => '26379', 'name' => 'mycluster', 'master_ip' => '127.0.0.1', 'master_port' => 6379}]
end

redisio_sentinel "redis-sentinels" do
  sentinel_defaults redis['sentinel_defaults']
  sentinels sentinel_instances
  base_piddir redis['base_piddir']
end

# Create a service resource for each sentinel instance, named for the port it runs on.
sentinel_instances.each do |current_sentinel|
  sentinel_name = current_sentinel['name']
  job_control   = node['redisio']['job_control']

  if job_control == 'initd'
  	service "redis_sentinel_#{sentinel_name}" do
      # don't supply start/stop/restart commands, Chef::Provider::Service::*
      # do a fine job on it's own, and support systemd correctly
      supports :start => true, :stop => true, :restart => true, :status => false
  	end
  elsif job_control == 'upstart'
    service "redis_sentinel_#{sentinel_name}" do
      provider Chef::Provider::Service::Upstart
      start_command "start redis_sentinel_#{sentinel_name}"
      stop_command "stop redis_sentinel_#{sentinel_name}"
      restart_command "restart redis_sentinel_#{sentinel_name}"
      supports :start => true, :stop => true, :restart => true, :status => false
    end
  else
    Chef::Log.error("Unknown job control type, no service resource created!")
  end

end
