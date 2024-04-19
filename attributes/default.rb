package_bin_path = '/usr/bin'
config_dir = '/etc/redis'
default_package_install = false

case node['platform_family']
when 'debian'
  shell = '/bin/false'
  homedir = '/var/lib/redis'
  package_name = 'redis-server'
when 'rhel', 'fedora'
  shell = '/bin/sh'
  homedir = '/var/lib/redis'
  package_name = 'redis'
when 'freebsd'
  shell = '/bin/sh'
  homedir = '/var/lib/redis'
  package_name = 'redis'
  package_bin_path = '/usr/local/bin'
  config_dir = '/usr/local/etc/redis'
  default_package_install = true
else
  shell = '/bin/sh'
  homedir = '/redis'
  package_name = 'redis'
end

# Overwite template used for the Redis Server config (not sentinel)
default['redisio']['redis_config']['template_cookbook'] = 'redisio'
default['redisio']['redis_config']['template_source'] = 'redis.conf.erb'

# Install related attributes
default['redisio']['safe_install'] = true
default['redisio']['package_install'] = default_package_install
default['redisio']['package_name'] =  package_name
default['redisio']['bypass_setup'] = false

# Tarball and download related defaults
default['redisio']['mirror'] = 'http://download.redis.io/releases/'
default['redisio']['base_name'] = 'redis-'
default['redisio']['artifact_type'] = 'tar.gz'
default['redisio']['base_piddir'] = '/var/run/redis'

# Version
default['redisio']['version'] = if node['redisio']['package_install']
                                  # latest version (only for package install)
                                  nil
                                else
                                  # force version for tarball
                                  '3.2.11'
                                end

# Custom installation directory
default['redisio']['install_dir'] = nil

# Job control related options (initd, upstart, or systemd)
default['redisio']['job_control'] = if systemd?
                                      'systemd'
                                    elsif platform_family?('freebsd')
                                      'rcinit'
                                    else
                                      'initd'
                                    end

# Init.d script related options
default['redisio']['init.d']['required_start'] = []
default['redisio']['init.d']['required_stop'] = []

# Default settings for all redis instances, these can be overridden on a per server basis in the 'servers' hash
default['redisio']['default_settings'] = {
  'user'                       => 'redis',
  'group'                      => 'redis',
  'permissions'                => '0644',
  'homedir'                    => homedir,
  'shell'                      => shell,
  'systemuser'                 => true,
  'uid'                        => nil,
  'ulimit'                     => 0,
  'configdir'                  => config_dir,
  'name'                       => nil,
  'tcpbacklog'                 => '511',
  'address'                    => nil,
  'databases'                  => '16',
  'backuptype'                 => 'rdb',
  'datadir'                    => '/var/lib/redis',
  'unixsocket'                 => nil,
  'unixsocketperm'             => nil,
  'timeout'                    => '0',
  'keepalive'                  => '0',
  'loglevel'                   => 'notice',
  'logfile'                    => nil,
  'syslogenabled'              => 'yes',
  'syslogfacility'             => 'local0',
  'shutdown_save'              => false,
  'save'                       => nil, # Defaults to ['900 1','300 10','60 10000'] inside of template. Needed due to lack of hash subtraction
  'stopwritesonbgsaveerror'    => 'yes',
  'rdbcompression'             => 'yes',
  'rdbchecksum'                => 'yes',
  'dbfilename'                 => nil,
  'replicaof'                  => nil,
  'protected_mode'             => nil, # unspecified by default but could be set explicitly to 'yes' or 'no'
  'masterauth'                 => nil,
  'replicaservestaledata'      => 'yes',
  'replicareadonly'            => 'yes',
  'repldisklesssync'           => 'no',
  'repldisklesssyncdelay'      => '5',
  'replpingreplicaperiod'      => '10',
  'repltimeout'                => '60',
  'repldisabletcpnodelay'      => 'no',
  'replbacklogsize'            => '1mb',
  'replbacklogttl'             => 3600,
  'replicapriority'            => '100',
  'requirepass'                => nil,
  'rename_commands'            => nil,
  'maxclients'                 => 10000,
  'maxmemory'                  => nil,
  'maxmemorypolicy'            => nil,
  'maxmemorysamples'           => nil,
  'appendfilename'             => nil,
  'appendfsync'                => 'everysec',
  'noappendfsynconrewrite'     => 'no',
  'aofrewritepercentage'       => '100',
  'aofrewriteminsize'          => '64mb',
  'aofloadtruncated'           => 'yes',
  'luatimelimit'               => '5000',
  'slowloglogslowerthan'       => '10000',
  'slowlogmaxlen'              => '1024',
  'notifykeyspaceevents'       => '',
  'hashmaxziplistentries'      => '512',
  'hashmaxziplistvalue'        => '64',
  'setmaxintsetentries'        => '512',
  'zsetmaxziplistentries'      => '128',
  'zsetmaxziplistvalue'        => '64',
  'hllsparsemaxbytes'          => '3000',
  'activerehasing'             => 'yes',
  'clientoutputbufferlimit'    => [
    %w(normal 0 0 0),
    %w(replica 256mb 64mb 60),
    %w(pubsub 32mb 8mb 60),
  ],
  'hz'                         => '10',
  'aofrewriteincrementalfsync' => 'yes',
  'clusterenabled'             => 'no',
  'clusterconfigfile'          => nil, # Defaults to redis instance name inside of template if cluster is enabled.
  'clusternodetimeout'         => 5000,
  'includes'                   => nil,
  'aclfile'                    => nil,
  'data_bag_name'              => nil,
  'data_bag_item'              => nil,
  'data_bag_key'               => nil,
  'minreplicastowrite'         => nil,
  'minreplicasmaxlag'          => nil,
  'breadcrumb'                 => true,
  'tlsport'                    => nil,
  'tlscertfile'                => nil,
  'tlskeyfile'                 => nil,
  'tlskeyfilepass'             => nil,
  'tlsclientcertfile'          => nil,
  'tlsclientkeyfile'           => nil,
  'tlsclientkeyfilepass'       => nil,
  'tlsdhparamsfile'            => nil,
  'tlscacertfile'              => nil,
  'tlscacertdir'               => nil,
  'tlsauthclients'             => nil,
  'tlsreplication'             => nil,
  'tlscluster'                 => nil,
  'tlsprotocols'               => nil,
  'tlsciphers'                 => nil,
  'tlsciphersuites'            => nil,
  'tlspreferserverciphers'     => nil,
  'tlssessioncaching'          => nil,
  'tlssessioncachesize'        => nil,
  'tlssessioncachetimeout'     => nil,
}

# The default for this is set inside of the "install" recipe. This is due to the way deep merge handles arrays
default['redisio']['servers'] = nil

# Define binary path
default['redisio']['bin_path'] = if node['redisio']['package_install']
                                   package_bin_path
                                 else
                                   '/usr/local/bin'
                                 end

# Ulimit
default['ulimit']['pam_su_template_cookbook'] = nil
default['ulimit']['users'] = Mash.new
default['ulimit']['security_limits_directory'] = '/etc/security/limits.d'
default['ulimit']['ulimit_overriding_sudo_file_name'] = 'sudo'
default['ulimit']['ulimit_overriding_sudo_file_cookbook'] = nil
