# frozen_string_literal: true

provides :redisio_configure
unified_mode true

property :version, [String, NilClass]
property :server_implementation, String, equal_to: %w(redis valkey), default: 'redis'
property :base_piddir, String, default: lazy { server_implementation == 'valkey' ? '/var/run/valkey' : '/var/run/redis' }
property :user, String, default: lazy { server_implementation == 'valkey' ? 'valkey' : 'redis' }
property :group, String, default: lazy { server_implementation == 'valkey' ? 'valkey' : 'redis' }
property :default_settings, Hash, default: {}
property :servers, [Array, NilClass], default: nil
property :package_install, [true, false], default: false
property :package_name, [String, NilClass]
property :install_dir, [String, NilClass]
property :bin_path, [String, NilClass]

action_class do
  include RedisioCookbook::Helpers

  def normalized_servers
    return [{ 'port' => 6379 }] if new_resource.servers.nil?

    normalize_array(new_resource.servers).map { |server| deep_stringify_keys(normalize_hash(server)) }
  end

  def merged_defaults(server)
    deep_stringify_keys(normalize_hash(new_resource.default_settings)).merge(server)
  end
end

action :create do
  normalized_servers.each do |server|
    merged = merged_defaults(server)
    instance_name = (merged['name'] || merged['port']).to_s

    redisio_server instance_name do
      version new_resource.version || merged['version']
      server_implementation new_resource.server_implementation
      base_piddir new_resource.base_piddir
      user merged.fetch('user', new_resource.user)
      group merged.fetch('group', new_resource.group)
      uid merged['uid']
      systemuser merged.fetch('systemuser', true)
      homedir merged['homedir']
      shell merged['shell']
      configdir merged['configdir']
      loglevel merged.fetch('loglevel', 'notice')
      logfile merged['logfile']
      syslogenabled merged.fetch('syslogenabled', 'yes')
      syslogfacility merged.fetch('syslogfacility', 'local0')
      protected_mode merged['protected_mode']
      maxclients merged.fetch('maxclients', 10_000)
      aclfile merged['aclfile']
      includes merged['includes']
      data_bag_name merged['data_bag_name']
      data_bag_item merged['data_bag_item']
      data_bag_key merged['data_bag_key']
      tlsport merged['tlsport']
      tlscertfile merged['tlscertfile']
      tlskeyfile merged['tlskeyfile']
      tlskeyfilepass merged['tlskeyfilepass']
      tlsclientcertfile merged['tlsclientcertfile']
      tlsclientkeyfile merged['tlsclientkeyfile']
      tlsclientkeyfilepass merged['tlsclientkeyfilepass']
      tlsdhparamsfile merged['tlsdhparamsfile']
      tlscacertfile merged['tlscacertfile']
      tlscacertdir merged['tlscacertdir']
      tlsauthclients merged['tlsauthclients']
      tlsreplication merged['tlsreplication']
      tlscluster merged['tlscluster']
      tlsprotocols merged['tlsprotocols']
      tlsciphers merged['tlsciphers']
      tlsciphersuites merged['tlsciphersuites']
      tlspreferserverciphers merged['tlspreferserverciphers']
      tlssessioncaching merged['tlssessioncaching']
      tlssessioncachesize merged['tlssessioncachesize']
      tlssessioncachetimeout merged['tlssessioncachetimeout']
      package_install new_resource.package_install
      package_name new_resource.package_name
      install_dir new_resource.install_dir
      bin_path new_resource.bin_path
      port merged.fetch('port', 6379)
      permissions merged.fetch('permissions', '0644')
      name_override merged['name']
      tcpbacklog merged.fetch('tcpbacklog', '511')
      address merged['address']
      databases merged.fetch('databases', '16')
      backuptype merged.fetch('backuptype', 'rdb')
      datadir merged.fetch('datadir', '/var/lib/redis')
      unixsocket merged['unixsocket']
      unixsocketperm merged['unixsocketperm']
      timeout merged.fetch('timeout', '0')
      keepalive merged.fetch('keepalive', '0')
      save merged['save']
      stopwritesonbgsaveerror merged.fetch('stopwritesonbgsaveerror', 'yes')
      rdbcompression merged.fetch('rdbcompression', 'yes')
      rdbchecksum merged.fetch('rdbchecksum', 'yes')
      dbfilename merged['dbfilename']
      replicaof merged['replicaof']
      masterauth merged['masterauth']
      replicaservestaledata merged.fetch('replicaservestaledata', 'yes')
      replicareadonly merged.fetch('replicareadonly', 'yes')
      repldisklesssync merged.fetch('repldisklesssync', 'no')
      repldisklesssyncdelay merged.fetch('repldisklesssyncdelay', '5')
      replpingreplicaperiod merged.fetch('replpingreplicaperiod', '10')
      repltimeout merged.fetch('repltimeout', '60')
      repldisabletcpnodelay merged.fetch('repldisabletcpnodelay', 'no')
      replbacklogsize merged.fetch('replbacklogsize', '1mb')
      replbacklogttl merged.fetch('replbacklogttl', 3600)
      replicapriority merged.fetch('replicapriority', '100')
      requirepass merged['requirepass']
      rename_commands merged['rename_commands']
      maxmemory merged['maxmemory']
      maxmemorypolicy merged['maxmemorypolicy']
      maxmemorysamples merged['maxmemorysamples']
      appendfilename merged['appendfilename']
      appendfsync merged.fetch('appendfsync', 'everysec')
      noappendfsynconrewrite merged.fetch('noappendfsynconrewrite', 'no')
      aofrewritepercentage merged.fetch('aofrewritepercentage', '100')
      aofrewriteminsize merged.fetch('aofrewriteminsize', '64mb')
      aofloadtruncated merged.fetch('aofloadtruncated', 'yes')
      luatimelimit merged.fetch('luatimelimit', '5000')
      slowloglogslowerthan merged.fetch('slowloglogslowerthan', '10000')
      slowlogmaxlen merged.fetch('slowlogmaxlen', '1024')
      notifykeyspaceevents merged.fetch('notifykeyspaceevents', '')
      hashmaxziplistentries merged.fetch('hashmaxziplistentries', '512')
      hashmaxziplistvalue merged.fetch('hashmaxziplistvalue', '64')
      setmaxintsetentries merged.fetch('setmaxintsetentries', '512')
      zsetmaxziplistentries merged.fetch('zsetmaxziplistentries', '128')
      zsetmaxziplistvalue merged.fetch('zsetmaxziplistvalue', '64')
      hllsparsemaxbytes merged.fetch('hllsparsemaxbytes', '3000')
      activerehasing merged.fetch('activerehasing', 'yes')
      clientoutputbufferlimit merged.fetch(
        'clientoutputbufferlimit',
        [
          %w(normal 0 0 0),
          %w(replica 256mb 64mb 60),
          %w(pubsub 32mb 8mb 60),
        ]
      )
      hz merged.fetch('hz', '10')
      aofrewriteincrementalfsync merged.fetch('aofrewriteincrementalfsync', 'yes')
      clusterenabled merged.fetch('clusterenabled', 'no')
      clusterconfigfile merged['clusterconfigfile']
      clusternodetimeout merged.fetch('clusternodetimeout', 5000)
      clusterport merged['clusterport']
      minreplicastowrite merged['minreplicastowrite']
      minreplicasmaxlag merged['minreplicasmaxlag']
      ulimit merged.fetch('ulimit', 0)
      breadcrumb merged.fetch('breadcrumb', true)
      template_cookbook merged.fetch('template_cookbook', 'redisio')
      template_source merged.fetch('template_source', 'redis.conf.erb')
      action new_resource.action
    end
  end
end
