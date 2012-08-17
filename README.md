Description
===========

Website:: https://github.com/brianbianco/redisio

Installs and configures Redis server instances

Requirements
============

This cookbook builds redis from source, so it should work on any architecture for the supported distributions.  Init scripts are installed into /etc/init.d/

Platforms
---------

* Debian, Ubuntu
* CentOS, Red Hat, Fedora, Scientific Linux

Tested on:

* Ubuntu 10.10, 12.04
* Debian 6.0
* Fedora 16
* Scientific Linux 6.2
* Centos 6.2

Usage
=====

The redisio cookbook has 3 LWRP's and 4 recipes.  For most use cases it isn't necessary to use the "install" LWRP and you should use the install recipe unless
you have a good understanding of the required fields for the install LWRP.  The service LWRP can be more useful if you have situations where you want to start,
stop, or restart the redis service based on certain conditions.

If all you are interested in is having redis started and running as well as set to run in the default run levels, I suggest just using the install recipe followed by the enable recipe and not using the LWRP directly.

I have provided a disable recipe as well which will stop redis and remove it from the defaults run levels.  There is also an uninstall LWRP, which will remove the redis binaries and optionally the init scripts and configuration files. It will NOT delete the redis data files files, that will have to be done manually.  I have provided for example and use, a redis uninstall recipe which will disable the service, remove the binaries, init scripts, and configuration files for all redis instances listed in the redisio['servers'] array.

It is important to note that changing the configuration options of redis does not make them take effect on the next chef run.  Due to how redis works, you cannot reload a configuration without restarting the redis service.  If you make a configuration change and you want it to take effect, you can either use the service LWRP to issue a restart to the servers you want via a cookbook you write, or you can use knife ssh to restart the redis service on the servers you want to change configuration on.

The cookbook also contains a recipe to allow for the installation of the redis ruby gem. 

Role File Examples
------------------

Install redis and setup an instance with default settings on default port, and start the service through a role file

```ruby
run_list *%w[
  recipe[redisio::install]
  recipe[redisio::enable]
]

default_attributes({})
```

Install redis and setup two instances on the same server, on different ports, with one slaved to the other through a role file

```ruby
run_list *%w[
  recipe[redisio::install]
  recipe[redisio::enable]
]

default_attributes({
  'redisio' => {
    'servers' => [
      {'port' => '6379'},
      {'port' => '6380', 'slaveof' => { 'address' => '127.0.0.1', 'port' => '6379' }}
    ]
  }
})
```

Install redis and setup two instances, on the same server, on different ports, with the data directory changed to /mnt/redis

```ruby
run_list *%w[
  recipe[redisio::install]
  recipe[redisio::enable]
]

default_attributes({
  'redisio' => {
    'default_settings' => {'datadir' => '/mnt/redis'},
    'servers' => [{'port' => '6379'}, {'port' => '6380'}]
  }
})
```

Install redis and setup three instances on the same server, changing the default data directory to /mnt/redis, each instance will use a different backup type, and one instance will use a different data dir

```ruby
run_list *%w[
  recipe[redisio::install]
  recipe[redisio::enable]
]

default_attributes({
  'redisio' => {
    'default_settings' => { 'datadir' => '/mnt/redis/'},
    'servers' => [
      {'port' => '6379','backuptype' => 'aof'},
      {'port' => '6380','backuptype' => 'both'}
      {'port' => '6381','backuptype' => 'rdb', 'datadir' => '/mnt/redis6381'}
    ]
  }
})
```

Install redis 2.4.11 (lower than the default version of 2.4.16) and turn safe install off, for the event where redis is already installed.  This will use the default settings.  Keep in mind the redis version will
not actually be updated until you restart the service (either through the LWRP or manually).

```ruby
run_list *%w[
  recipe[redisio::install]
  recipe[redisio::enable]
]

default_attributes({
  'redisio' => {
    'safe_install' => false,
    'version'      => '2.4.11'
  }
})
```

Install version 2.2.2 of the redis ruby gem, if you don't list the version, it will simply install the latest available.

```ruby
run_list *%w[
  recipe[redisio::redis_gem]
]

default_attributes({
  'redisio' => {
    'gem' => {
      'version' => '2.2.2'
    }
  }
})
```

LWRP Examples
-------------

Instead of using my provided recipes, you can simply include the redisio default in your role and use the LWRP's yourself.  I will show a few examples of ways to use the LWRPS, detailed breakdown of options are below
in the resources/providers section

install resource
----------------

It is important to note that this call has certain expectations for example, it expects the redis package to be in the format `redis-VERSION.tar.gz'.  The servers resource expects an array of hashes where each hash is required to contain at a key-value pair of 'port' => '<port numbers>'.

```ruby
redisio_install "redis-servers" do
  version '2.4.10'
  download_url 'http://redis.googlecode.com/files/redis-2.4.10.tar.gz'
  default_settings node['redisio']['default_settings']
  servers node['redisio']['servers']
  safe_install false
  base_piddir node['redisio']['base_piddir']
end
```

uninstall resource
------------------

I generally don't recommend using this LWRP or recipe at all, but in the event you really want to remove files, these are available.


This will only remove the redis binary files if they exist, nothing else.

```ruby
redisio_uninstall "redis-servers" do
  action :run
end
```

This will remove the redis binaries, as well as the init script and configuration files for the specified server. This will not remove any data files

```ruby
redisio_uninstall "redis-servers" do
  servers [{'port' => '6379'}]
  action :run
end
```

service resource
----------------

This LWRP provides the ability to stop, start, restart, disable and enable the redis service.

Start and add to default runlevels the instance running on port 6379

```ruby
redisio_service "6379" do
  action [:start,:enable]
end
```

Stop and remove from default runlevels the instance running on port 6379

```ruby
redisio_service "6379" do
  action [:stop,:disable]
end
```

Restart the instance running on port 6380

```ruby
redisio_service "6380" do
  action [:restart]
end
```

Attributes
==========

Configuration options, each option corresponds to the same-named configuration option in the redis configuration file;  default values listed

* `redisio['mirror']` - mirror server with path to download redis package, default is https://redis.googlecode.com/files
* `redisio['base_name']` - the base name of the redis package to be downloaded (the part before the version), default is 'redis-'
* `redisio['artifact_type']` - the file extension of the package.  currently only .tar.gz and .tgz are supported, default is 'tar.gz'
* `redisio['version']` - the version number of redis to install (also appended to the `base_name` for downloading), default is '2.4.10'
* `redisio['safe_install'] - prevents redis from installing itself if another version of redis is installed, default is true
* `redisio['base_piddir'] - This is the directory that redis pidfile directories and pidfiles will be placed in.  Since redis can run as non root, it needs to have proper
                           permissions to the directory to create its pid.  Since each instance can run as a different user, these directories will all be nested inside this base one.

Default settings is a hash of default settings to be applied to to ALL instances.  These can be overridden for each individual server in the servers attribute.  If you are going to set logfile to a specific file, make sure to set syslog-enabled to no.

* `redisio['default_settings']` - { 'redis-option' => 'option setting' }

Available options and their defaults

```
'user'                   => 'redis' - the user to own the redis datadir, redis will also run under this user
'group'                  => 'redis' - the group to own the redis datadir
'homedir'                => Home directory of the user. Varies on distribution, check attributes file 
'shell'                  => Users shell. Varies on distribution, check attributes file
'configdir'              => '/etc/redis' - configuration directory
'address'                => nil,
'databases'              => '16',
'backuptype'             => 'rdb',
'datadir'                => '/var/lib/redis',
'timeout'                => '0',
'loglevel'               => 'verbose',
'logfile'                => nil,
'syslogenabled'         => 'yes',,
'syslogfacility         => 'local0',
'save'                   => ['900 1','300 10','60 10000'],
'slaveof'                => nil,
'masterauth'             => nil,
'slaveservestaledata'    => 'yes',
'replpingslaveperiod'    => '10',
'repltimeout'            => '60',
'requirepass'            => nil,
'maxclients'             => '10000',
'maxmemory'              => nil,
'maxmemorypolicy'        => 'volatile-lru',
'maxmemorysamples'       => '3',
'appendfsync'            => 'everysec',
'noappendfsynconrewrite' => 'no',
'aofrewritepercentage'   => '100',
'aofrewriteminsize'      => '64mb',
'includes'               => nil
```

* `redisio['servers']` - An array where each item is a set of key value pairs for redis instance specific settings.  The only required option is 'port'.  These settings will override the options in 'default_settings', default is set to [{'port' => '6379'}]

The redis_gem recipe  will also allow you to install the redis ruby gem, these are attributes related to that, and are in the redis_gem attributes file.

* `redisio['gem']['name']` - the name of the gem to install, defaults to 'redis'  
* `redisio['gem']['version']` -  the version of the gem to install.  if it is nil, the latest available version will be installed.

Resources/Providers
===================

This cookbook contains 3 LWRP's

`install`
--------

Actions:

* `run` - perform the install (default)
* `nothing` - do nothing

Attribute Parameters

* `version` - the version of redis to download / install
* `download_url` - the URL plus filename of the redis package to install
* `download_dir` - the directory to store the downloaded package
* `artifact_type` - the file extension of the package
* `base_name` - the name of the package minus the extension and version number
* `user` - the user to run redis as, and to own the redis files
* `group` - the group to own the redis files
* `default_settings` - a hash of the default redis server settings
* `servers` - an array of hashes containing server configurations overrides (port is the only required)
* `safe_install` - a true or false value which determines if a version of redis will be installed if one already exists, defaults to true

This resource expects the following naming conventions:

package file should be in the format <base_name><version_number>.<artifact_type>

package file after extraction should be inside of the directory <base_name><version_number>

```ruby
install "redis" do
  action [:run,:nothing]
end
```

`uninstall`
----------

Actions:

* `run` - perform the uninstall
* `nothing` - do nothing (default)

Attribute Parameters

* `servers` - an array of hashes containing the port number of instances to remove along with the binarires.  (it is fine to pass in the same hash you used to install, even if there are additional
              only the port is used)

```ruby
uninstall "redis" do
  action [:run,:nothing]
end
```

`service`
---------

Actions:

* `start`
* `stop`
* `restart`
* `enable`
* `disable`

The name of the service must be the port that the redis server you want to perform the action on is identified by

```ruby
service "redis_port" do
  action [:start,:stop,:restart,:enable,:disable]
end
```

License and Author
==================

Author:: [Brian Bianco] (<brian.bianco@gmail.com>)
Author\_Website:: http://www.brianbianco.com
Twitter:: @brianwbianco
IRC:: geekbri

Copyright 2012, Brian Bianco

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

