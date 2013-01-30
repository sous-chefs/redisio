#
# Cookbook Name:: redisio
# Recipe:: install
#
# Copyright 2012, Brian Bianco <brian.bianco@gmail.com>
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

redis = node['redisio']
location = "#{redis['mirror']}/#{redis['base_name']}#{redis['version']}.#{redis['artifact_type']}"

redisio_install "redis-servers" do
  version redis['version']
  download_url location
  default_settings redis['default_settings']
  servers redis['servers']
  safe_install redis['safe_install']
  base_piddir redis['base_piddir']
end

# Create a service resource for each redis instance, named for the port it runs on.
redis['servers'].each do |current_server|
  if current_server['job_control'] == 'initd'
  	service "redis#{current_server['port']}" do
      start_command "/etc/init.d/redis#{current_server['port']} start"
      stop_command "/etc/init.d/redis#{current_server['port']} stop"
      status_command "pgrep -lf 'redis.*#{current_server['port']}' | grep -v 'sh'"
      restart_command "/etc/init.d/redis#{current_server['port']} start && /etc/init.d/redis#{current_server['port']} start"
      supports :start => true, :stop => true, :restart => true, :status => false
  	end
  elsif current_server['job_control'] == 'upstart'
  	service "redis#{current_server['port']}" do
	  provider Chef::Provider::Service::Upstart
      start_command "start redis#{current_server['port']}"
      stop_command "stop redis#{current_server['port']}"
      status_command "pgrep -lf 'redis.*#{current_server['port']}' | grep -v 'sh'"
      restart_command "restart redis#{current_server['port']}"
      supports :start => true, :stop => true, :restart => true, :status => false
  	end
  else
  	service "redis#{current_server['port']}" do
      supports :start => false, :stop => false, :restart => false, :status => false
  	end
  end
end

