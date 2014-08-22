# Cookbook Name:: redisio
# Attribute::default
#
# Copyright 2013, Brian Bianco <brian.bianco@gmail.com>
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

case node['platform']
when 'ubuntu','debian'
  shell = '/bin/false'
  homedir = '/var/lib/redis'
when 'centos','redhat','scientific','amazon','suse'
  shell = '/bin/sh'
  homedir = '/var/lib/redis'
when 'fedora'
  shell = '/bin/sh'
  homedir = '/home' #this is necessary because selinux by default prevents the homedir from being managed in /var/lib/
else
  shell = '/bin/sh'
  homedir = '/redis'
end

# Install related attributes
default['redisio']['safe_install'] = true
default['redisio']['bypass_setup'] = false

# Tarball and download related defaults
default['redisio']['mirror'] = "http://download.redis.io/releases/"
default['redisio']['base_name'] = 'redis-'
default['redisio']['artifact_type'] = 'tar.gz'
default['redisio']['version'] = '2.8.13'
default['redisio']['base_piddir'] = '/var/run/redis'

# Custom installation directory
default['redisio']['install_dir'] = nil

# Job control related options (initd or upstart)
default['redisio']['job_control'] = 'initd'

# Init.d script related options
default['redisio']['init.d']['required_start'] = []
default['redisio']['init.d']['required_stop'] = []

# Default settings for all redis instances, these can be overridden on a per server basis in the 'servers' hash
default['redisio']['default_settings'] = {
  'user'                    => 'redis',
  'group'                   => 'redis',
  'homedir'                 => homedir,
  'shell'                   => shell,
  'systemuser'              => true,
  'ulimit'                  => 0,
  'configdir'               => '/etc/redis',
  'name'                    => nil,
  'address'                 => nil,
  'databases'               => '16',
  'backuptype'              => 'rdb',
  'datadir'                 => '/var/lib/redis',
  'unixsocket'              => nil,
  'unixsocketperm'          => nil,
  'timeout'                 => '0',
  'keepalive'               => '0',
  'loglevel'                => 'notice',
  'logfile'                 => nil,
  'syslogenabled'           => 'yes',
  'syslogfacility'          => 'local0',
  'shutdown_save'           => false,
  'save'                    => nil, # Defaults to ['900 1','300 10','60 10000'] inside of template.  Needed due to lack of hash subtraction
  'stopwritesonbgsaveerror' => 'yes',
  'slaveof'                 => nil,
  'masterauth'              => nil,
  'slaveservestaledata'     => 'yes',
  'replpingslaveperiod'     => '10',
  'repltimeout'             => '60',
  'requirepass'             => nil,
  'maxclients'              => 10000,
  'maxmemory'               => nil,
  'maxmemorypolicy'         => nil,
  'maxmemorysamples'        => nil,
  'appendfsync'             => 'everysec',
  'noappendfsynconrewrite'  => 'no',
  'aofrewritepercentage'    => '100',
  'aofrewriteminsize'       => '64mb',
  'luatimelimit'            => '5000',
  'slowloglogslowerthan'    => '10000',
  'slowlog-max-len'         => '1024',
  'notifykeyspaceevents'    => '',
  'hashmaxziplistentries'   => '512',
  'hashmaxziplistvalue'     => '64',
  'setmaxintsetentries'     => '512',
  'zsetmaxziplistentries'   => '128',
  'zsetmaxziplistvalue'     => '64',
  'activerehasing'          => 'yes',
  'clientoutputbufferlimit' => [
    %w(normal 0 0 0),
    %w(slave 256mb 64mb 60),
    %w(pubsub 32mb 8mb 60)
  ],
  'hz'                         => '10',
  'aofrewriteincrementalfsync' => 'yes',
  'cluster-enabled'            => 'no',
  'cluster-config-file'        => nil, # Defaults to redis instance name inside of template if cluster is enabled.
  'cluster-node-timeout'       => 5,
  'includes'                   => nil
}

# The default for this is set inside of the "install" recipe. This is due to the way deep merge handles arrays
default['redisio']['servers'] = nil

