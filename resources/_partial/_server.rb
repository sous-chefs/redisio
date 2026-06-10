# frozen_string_literal: true

property :port, [String, Integer], default: 6379
property :permissions, String, default: '0644'
property :name_override, default: nil
property :tcpbacklog, String, default: '511'
property :address, default: nil
property :databases, String, default: '16'
property :backuptype, String, default: 'rdb'
property :datadir, String, default: lazy { server_implementation == 'valkey' ? '/var/lib/valkey' : '/var/lib/redis' }
property :unixsocket, default: nil
property :unixsocketperm, default: nil
property :timeout, String, default: '0'
property :keepalive, String, default: '0'
property :save, default: nil
property :stopwritesonbgsaveerror, String, default: 'yes'
property :rdbcompression, String, default: 'yes'
property :rdbchecksum, String, default: 'yes'
property :dbfilename, default: nil
property :replicaof, default: nil
property :masterauth, default: nil
property :replicaservestaledata, String, default: 'yes'
property :replicareadonly, String, default: 'yes'
property :repldisklesssync, String, default: 'no'
property :repldisklesssyncdelay, String, default: '5'
property :replpingreplicaperiod, String, default: '10'
property :repltimeout, String, default: '60'
property :repldisabletcpnodelay, String, default: 'no'
property :replbacklogsize, String, default: '1mb'
property :replbacklogttl, default: 3600
property :replicapriority, String, default: '100'
property :requirepass, default: nil
property :rename_commands, default: nil
property :maxmemory, default: nil
property :maxmemorypolicy, default: nil
property :maxmemorysamples, default: nil
property :appendfilename, default: nil
property :appendfsync, String, default: 'everysec'
property :noappendfsynconrewrite, String, default: 'no'
property :aofrewritepercentage, String, default: '100'
property :aofrewriteminsize, String, default: '64mb'
property :aofloadtruncated, String, default: 'yes'
property :luatimelimit, String, default: '5000'
property :slowloglogslowerthan, String, default: '10000'
property :slowlogmaxlen, String, default: '1024'
property :notifykeyspaceevents, String, default: ''
property :hashmaxziplistentries, String, default: '512'
property :hashmaxziplistvalue, String, default: '64'
property :setmaxintsetentries, String, default: '512'
property :zsetmaxziplistentries, String, default: '128'
property :zsetmaxziplistvalue, String, default: '64'
property :hllsparsemaxbytes, String, default: '3000'
property :activerehasing, String, default: 'yes'
property :clientoutputbufferlimit, default: [
  %w(normal 0 0 0),
  %w(replica 256mb 64mb 60),
  %w(pubsub 32mb 8mb 60),
]
property :hz, String, default: '10'
property :aofrewriteincrementalfsync, String, default: 'yes'
property :clusterenabled, String, default: 'no'
property :clusterconfigfile, default: nil
property :clusternodetimeout, default: 5000
property :clusterport, default: nil
property :minreplicastowrite, default: nil
property :minreplicasmaxlag, default: nil
property :ulimit, Integer, default: 0
property :breadcrumb, [true, false], default: true
property :template_cookbook, String, default: 'redisio'
property :template_source, String, default: 'redis.conf.erb'
