#
# Cookbook Name:: redisio
# Provider::configure
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

action :run do
  configure
  new_resource.updated_by_last_action(true)
end

def configure
  base_piddir = new_resource.base_piddir
  version_hash = RedisioHelper.version_to_hash(new_resource.version)

  #Setup a configuration file and init script for each configuration provided
  new_resource.servers.each do |current_instance|

    #Retrieve the default settings hash and the current server setups settings hash.
    current_instance_hash = current_instance.to_hash
    current_defaults_hash = new_resource.default_settings.to_hash

    #Merge the configuration defaults with the provided array of configurations provided
    current = current_defaults_hash.merge(current_instance_hash)

    #Merge in the default maxmemory
    node_memory_kb = node["memory"]["total"]
    node_memory_kb.slice! "kB"
    node_memory_kb = node_memory_kb.to_i

    # Here we determine what the logfile is.  It has these possible states
    #
    # Redis 2.6 and lower can be
    #   stdout
    #   A path
    #   nil
    # Redis 2.8 and higher can be
    #   empty string, which means stdout)
    #   A path
    #   nil

    if current['logfile'].nil?
      log_file = nil
      log_directory = nil
    else
      if current['logfile'] == 'stdout' || current['logfile'].empty?
        log_directory = nil
        log_file = current['logfile']
      else
        log_directory = ::File.dirname(current['logfile'])
        log_file      = ::File.basename(current['logfile'])
        if current['syslogenabled'] == 'yes'
          Chef::Log.warn("log file is set to #{current['logfile']} but syslogenabled is also set to 'yes'")
        end
      end
    end

    maxmemory = current['maxmemory'].to_s
    if !maxmemory.empty? && maxmemory.include?("%")
      # Just assume this is sensible like "95%" or "95 %"
      percent_factor = current['maxmemory'].to_f / 100.0
      # Ohai reports memory in KB as it looks in /proc/meminfo
      maxmemory = (node_memory_kb * 1024 * percent_factor / new_resource.servers.length).round.to_s
    end

    descriptors = current['ulimit'] == 0 ? current['maxclients'] + 32 : current['maxclients']

    #Manage Redisio Config?
    if node['redisio']['sentinel']['manage_config'] == true
      config_action = :create
    else
      config_action = :create_if_missing
    end

    recipe_eval do
      server_name = current['name'] || current['port']
      piddir = "#{base_piddir}/#{server_name}"
      aof_file = "#{current['datadir']}/appendonly-#{server_name}.aof"
      rdb_file = "#{current['datadir']}/dump-#{server_name}.rdb"

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
      #Create the instance data directory
      directory current['datadir'] do
        owner current['user']
        group current['group']
        mode '0775'
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
      #Create the log directory if syslog is not being used
      if log_directory
        directory log_directory do
          owner current['user']
          group current['group']
          mode '0755'
          recursive true
          action :create
          only_if { log_directory }
        end
      end
      #Create the log file if syslog is not being used
      if log_file
        file current['logfile'] do
          owner current['user']
          group current['group']
          mode '0644'
          backup false
          action :touch
          # in version 2.8 or higher the empty string is used instead of stdout
          only_if { !log_file.empty? && log_file != "stdout" }
        end
      end
      #Set proper permissions on the AOF or RDB files
      file aof_file do
        owner current['user']
        group current['group']
        mode '0644'
        only_if { current['backuptype'] == 'aof' || current['backuptype'] == 'both' }
        only_if { ::File.exists?(aof_file) }
      end
      file rdb_file  do
        owner current['user']
        group current['group']
        mode '0644'
        only_if { current['backuptype'] == 'rdb' || current['backuptype'] == 'both' }
        only_if { ::File.exists?(rdb_file) }
      end
      #Setup the redis users descriptor limits
      user_ulimit current['user'] do
        filehandle_limit descriptors
        only_if { current['ulimit'] }
      end
      
      #Lay down the configuration files for the current instance
      template "#{current['configdir']}/#{server_name}.conf" do
        source 'redis.conf.erb'
        cookbook 'redisio'
        owner current['user']
        group current['group']
        mode '0644'
        action config_action
        variables({
          :version                    => version_hash,
          :piddir                     => piddir,
          :name                       => server_name,
          :job_control                => node['redisio']['job_control'],
          :port                       => current['port'],
          :address                    => current['address'],
          :databases                  => current['databases'],
          :backuptype                 => current['backuptype'],
          :datadir                    => current['datadir'],
          :unixsocket                 => current['unixsocket'],
          :unixsocketperm             => current['unixsocketperm'],
          :timeout                    => current['timeout'],
          :keepalive                  => current['keepalive'],
          :loglevel                   => current['loglevel'],
          :logfile                    => current['logfile'],
          :syslogenabled              => current['syslogenabled'],
          :syslogfacility             => current['syslogfacility'],
          :save                       => current['save'],
          :stopwritesonbgsaveerror    => current['stopwritesonbgsaveerror'],
          :slaveof                    => current['slaveof'],
          :masterauth                 => current['masterauth'],
          :slaveservestaledata        => current['slaveservestaledata'],
          :replpingslaveperiod        => current['replpingslaveperiod'],
          :repltimeout                => current['repltimeout'],
          :requirepass                => current['requirepass'],
          :maxclients                 => current['maxclients'],
          :maxmemory                  => maxmemory,
          :maxmemorypolicy            => current['maxmemorypolicy'],
          :maxmemorysamples           => current['maxmemorysamples'],
          :appendfsync                => current['appendfsync'],
          :noappendfsynconrewrite     => current['noappendfsynconrewrite'],
          :aofrewritepercentage       => current['aofrewritepercentage'] ,
          :aofrewriteminsize          => current['aofrewriteminsize'],
          :luatimelimit               => current['luatimelimit'],
          :slowloglogslowerthan       => current['slowloglogslowerthan'],
          :slowlogmaxlen              => current['slowlogmaxlen'],
          :notifykeyspaceevents       => current['notifykeyspaceevents'],
          :hashmaxziplistentries      => current['hashmaxziplistentries'],
          :hashmaxziplistvalue        => current['hashmaxziplistvalue'],
          :setmaxintsetentries        => current['setmaxintsetentries'],
          :zsetmaxziplistentries      => current['zsetmaxziplistentries'],
          :zsetmaxziplistvalue        => current['zsetmaxziplistvalue'],
          :activerehasing             => current['activerehasing'],
          :clientoutputbufferlimit    => current['clientoutputbufferlimit'],
          :hz                         => current['hz'],
          :aofrewriteincrementalfsync => current['aofrewriteincrementalfsync'],
          :clusterenabled             => current['clusterenabled'],
          :clusterconfigfile          => current['clusterconfigfile'],
          :clusternodetimeout         => current['clusternodetimeout'],
          :includes                   => current['includes']
        })
      end
      #Setup init.d file
      bin_path = "/usr/local/bin"
      bin_path = ::File.join(node['redisio']['install_dir'], 'bin') if node['redisio']['install_dir']
      template "/etc/init.d/redis#{server_name}" do
        source 'redis.init.erb'
        cookbook 'redisio'
        owner 'root'
        group 'root'
        mode '0755'
        variables({
          :name => server_name,
          :bin_path => bin_path,
          :job_control => node['redisio']['job_control'],
          :port => current['port'],
          :address => current['address'],
          :user => current['user'],
          :configdir => current['configdir'],
          :piddir => piddir,
          :requirepass => current['requirepass'],
          :shutdown_save => current['shutdown_save'],
          :platform => node['platform'],
          :unixsocket => current['unixsocket'],
          :ulimit => descriptors,
          :required_start => node['redisio']['init.d']['required_start'].join(" "),
          :required_stop => node['redisio']['init.d']['required_stop'].join(" ")
          })
        only_if { node['redisio']['job_control'] == 'initd' }
      end
      template "/etc/init/redis#{server_name}.conf" do
        source 'redis.upstart.conf.erb'
        cookbook 'redisio'
        owner current['user']
        group current['group']
        mode '0644'
        variables({
          :name => server_name,
          :bin_path => bin_path,
          :job_control => node['redisio']['job_control'],
          :port => current['port'],
          :address => current['address'],
          :user => current['user'],
          :group => current['group'],
          :maxclients => current['maxclients'],
          :requirepass => current['requirepass'],
          :shutdown_save => current['shutdown_save'],
          :save => current['save'],
          :configdir => current['configdir'],
          :piddir => piddir,
          :platform => node['platform'],
          :unixsocket => current['unixsocket']
        })
        only_if { node['redisio']['job_control'] == 'upstart' }
      end
    end
  end # servers each loop
end

def load_current_resource
  @current_resource = Chef::Resource::RedisioConfigure.new(new_resource.name)
  @current_resource
end
