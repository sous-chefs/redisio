#
# Cookbook Name:: redisio
# Recipe:: configure
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
include_recipe 'redisio::default'
include_recipe 'ulimit::default'

redis = node['redisio']

redis_instances = redis['servers']
if redis_instances.nil?
  redis_instances = [{'port' => '6379'}]
end

redisio_configure "redis-servers" do
  version redis['version']
  default_settings redis['default_settings']
  servers redis_instances
  base_piddir redis['base_piddir']
end

# Create a service resource for each redis instance, named for the port it runs on.
redis_instances.each do |current_server|
  server_name = current_server['name'] || current_server['port']
  job_control = node['redisio']['job_control']

  if job_control == 'initd'
  	service "redis#{server_name}" do
      # don't supply start/stop/restart commands, Chef::Provider::Service::*
      # do a fine job on it's own, and support systemd correctly
      supports :start => true, :stop => true, :restart => false, :status => true
  	end
  elsif job_control == 'upstart'
  	service "redis#{server_name}" do
	  provider Chef::Provider::Service::Upstart
      start_command "start redis#{server_name}"
      stop_command "stop redis#{server_name}"
      restart_command "restart redis#{server_name}"
      supports :start => true, :stop => true, :restart => true, :status => false
  	end
  else
    Chef::Log.error("Unknown job control type, no service resource created!")
  end

end

node.set['redisio']['servers'] = redis_instances
