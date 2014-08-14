#
# Cookbook Name:: redisio
# Provider::sentinel
#
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

action :run do
  configure
  new_resource.updated_by_last_action(true)
end

def configure
  base_piddir = new_resource.base_piddir

  #Setup a configuration file and init script for each configuration provided
  new_resource.sentinels.each do |current_instance|

    #Retrieve the default settings hash and the current server setups settings hash.
    current_instance_hash = current_instance.to_hash
    current_defaults_hash = new_resource.sentinel_defaults.to_hash

    #Merge the configuration defaults with the provided array of configurations provided
    current = current_defaults_hash.merge(current_instance_hash)

    #Manage Sentinel Configs?
    if node['redisio']['sentinel']['manage_config'] == true
      config_action = :create
    else
      config_action = :create_if_missing
    end

    recipe_eval do
      sentinel_name = current['name'] || current['port']
      sentinel_name = "sentinel_#{sentinel_name}"
      piddir = "#{base_piddir}/#{sentinel_name}"

      #Create the owner of the redis data directory
      user current['user'] do
        comment 'Redis service account'
        supports :manage_home => true
        home current['homedir']
        shell current['shell']
        system current['systemuser']
      end
      #Create the redis configuration directory
      directory current['configdir'] do
        owner 'root'
        group 'root'
        mode '0755'
        recursive true
        action :create
      end
      #Create the pid file directory
      directory piddir do
        owner current['user']
        group current['group']
        mode '0755'
        recursive true
        action :create
      end
     
    unless current['logfile'].nil?
      #Create the log directory if syslog is not being used
      directory ::File.dirname(current['logfile']) do
        owner current['user']
        group current['group']
        mode '0755'
        recursive true
        action :create
        only_if { current['syslogenabled'] != 'yes' && current['logfile'] && current['logfile'] != 'stdout' }
      end
    
     #Create the log file is syslog is not being used
      file current['logfile'] do
        owner current['user']
        group current['group']
        mode '0644'
        backup false
        action :touch
        only_if { current['logfile'] && current['logfile'] != 'stdout' }
      end
    end

      #Lay down the configuration files for the current instance
      template "#{current['configdir']}/#{sentinel_name}.conf" do
        source 'sentinel.conf.erb'
        cookbook 'redisio'
        owner current['user']
        group current['group']
        mode '0644'
        action config_action
        variables({
          :piddir                 => piddir,
          :name                   => sentinel_name,
          :job_control            => node['redisio']['job_control'],
          :sentinel_port          => current['sentinel_port'],
          :masterip               => current['master_ip'],
          :masterport             => current['master_port'],
          :authpass               => current['auth-pass'],
          :downaftermil           => current['down-after-milliseconds'],
          :canfailover            => current['can-failover'],
          :parallelsyncs          => current['parallel-syncs'],
          :failovertimeout        => current['failover-timeout'],
          :loglevel               => current['loglevel'],
          :logfile                => current['logfile'],
          :syslogenabled          => current['syslogenabled'],
          :syslogfacility         => current['syslogfacility'],
          :quorum_count           => current['quorum_count']
        })
      end
      #Setup init.d file
      bin_path = "/usr/local/bin"
      bin_path = ::File.join(node['redisio']['install_dir'], 'bin') if node['redisio']['install_dir']
      template "/etc/init.d/redis_#{sentinel_name}" do
        source 'sentinel.init.erb'
        cookbook 'redisio'
        owner 'root'
        group 'root'
        mode '0755'
        variables({
          :name => sentinel_name,
          :bin_path => bin_path,
          :uob_control => node['redisio']['job_control'],
          :user => current['user'],
          :configdir => current['configdir'],
          :piddir => piddir,
          :platform => node['platform'],
          })
        only_if { node['redisio']['job_control'] == 'initd' }
      end
      template "/etc/init/redis_#{sentinel_name}.conf" do
        source 'sentinel.upstart.conf.erb'
        cookbook 'redisio'
        owner current['user']
        group current['group']
        mode '0644'
        variables({
          :name => sentinel_name,
          :bin_path => bin_path,
          :job_control => node['redisio']['job_control'],
          :user => current['user'],
          :group => current['group'],
          :configdir => current['configdir'],
          :piddir => piddir,
          :platform => node['platform'],
          })
        only_if { node['redisio']['job_control'] == 'upstart' }
      end
    end
  end # servers each loop
end

def load_current_resource
  @current_resource = Chef::Resource::RedisioSentinel.new(new_resource.name)
  @current_resource
end
