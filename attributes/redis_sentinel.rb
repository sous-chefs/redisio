config_dir = if platform_family?('freebsd')
               '/usr/local/etc/redis'
             else
               '/etc/redis'
             end

default['redisio']['sentinel_defaults'] = {
  'user'                    => 'redis',
  'configdir'               => config_dir,
  'sentinel_bind'           => nil,
  'sentinel_port'           => 26379,
  'monitor'                 => nil,
  'down_after_milliseconds' => 30000,
  'can-failover'            => 'yes',
  'parallel-syncs'          => 1,
  'failover_timeout'        => 900000,
  'loglevel'                => 'notice',
  'logfile'                 => nil,
  'syslogenabled'           => 'yes',
  'syslogfacility'          => 'local0',
  'quorum_count'            => 2,
  'data_bag_name'           => nil,
  'data_bag_item'           => nil,
  'data_bag_key'            => nil,
  'announce-ip'             => nil,
  'announce-port'           => nil,
  'notification-script'     => nil,
  'client-reconfig-script'  => nil,
  'protected_mode'          => nil,
  'maxclients'              => 10000,
  'aclfile'                 => nil,
  'includes'                => nil,
  'tlsport'                 => nil,
  'tlscertfile'             => nil,
  'tlskeyfile'              => nil,
  'tlskeyfilepass'          => nil,
  'tlsclientcertfile'       => nil,
  'tlsclientkeyfile'        => nil,
  'tlsclientkeyfilepass'    => nil,
  'tlsdhparamsfile'         => nil,
  'tlscacertfile'           => nil,
  'tlscacertdir'            => nil,
  'tlsauthclients'          => nil,
  'tlsreplication'          => nil,
  'tlscluster'              => nil,
  'tlsprotocols'            => nil,
  'tlsciphers'              => nil,
  'tlsciphersuites'         => nil,
  'tlspreferserverciphers'  => nil,
  'tlssessioncaching'       => nil,
  'tlssessioncachesize'     => nil,
  'tlssessioncachetimeout'  => nil,
}

# Manage Sentinel Config File
## Will write out the base config one time then no longer manage the config allowing sentinel to take over
default['redisio']['sentinel']['manage_config'] = true # Deprecated

default['redisio']['sentinels'] = nil
