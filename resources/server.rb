# frozen_string_literal: true

provides :redisio_server
unified_mode true

use '_partial/_base'
use '_partial/_server'

property :instance_name, String, name_property: true

action_class do
  include RedisioCookbook::Helpers
  include Chef::Util::Selinux

  def resolved_instance_name
    (new_resource.name_override || new_resource.instance_name).to_s
  end

  def resolved_user
    new_resource.user
  end

  def resolved_group
    new_resource.group || platform_default_group
  end

  def resolved_homedir
    new_resource.homedir || platform_default_home
  end

  def resolved_shell
    new_resource.shell || platform_default_shell
  end

  def resolved_configdir
    new_resource.configdir || platform_default_config_dir
  end

  def resolved_bin_path
    new_resource.bin_path || platform_default_bin_path(package_install: new_resource.package_install, install_dir: new_resource.install_dir)
  end

  def resolved_package_name
    new_resource.package_name || platform_package_name
  end

  def resolved_version
    return new_resource.version if new_resource.version
    return '7.0.0' if new_resource.package_install

    installed_redis_version(resolved_bin_path, package_install: new_resource.package_install, package_name: resolved_package_name)
  end

  def resolved_version_hash
    redis_version_to_hash(resolved_version || '0.0.0')
  end

  def resolved_piddir
    ::File.join(new_resource.base_piddir, resolved_instance_name)
  end

  def resolved_log_directory
    return if new_resource.logfile.nil?
    return if new_resource.logfile.empty? || new_resource.logfile == 'stdout'

    ::File.dirname(new_resource.logfile)
  end

  def resolved_log_file
    return if new_resource.logfile.nil?
    return if new_resource.logfile.empty? || new_resource.logfile == 'stdout'

    new_resource.logfile
  end

  def resolved_descriptors
    if new_resource.ulimit.zero?
      new_resource.maxclients + 32
    else
      [new_resource.ulimit, new_resource.maxclients].max
    end
  end

  def resolved_maxmemory(server_count = 1)
    maxmemory = new_resource.maxmemory.to_s
    return new_resource.maxmemory if maxmemory.empty? || !maxmemory.include?('%')

    node_memory_kb = node['memory']['total']
    node_memory_kb = node_memory_kb.delete_suffix('kB').to_i if node_memory_kb.is_a?(String)
    ((node_memory_kb * 1024 * (new_resource.maxmemory.to_f / 100.0)) / server_count).round.to_s
  end

  def resolved_save
    return new_resource.save.each_line.to_a if new_resource.save.respond_to?(:each_line) && !new_resource.save.is_a?(Array)

    new_resource.save
  end

  def resolved_data_bag_secret
    return {} unless new_resource.data_bag_name && new_resource.data_bag_item && new_resource.data_bag_key

    bag = data_bag_item(new_resource.data_bag_name, new_resource.data_bag_item)
    {
      requirepass: bag[new_resource.data_bag_key],
      masterauth: bag[new_resource.data_bag_key],
    }
  end

  def resolved_append_file
    ::File.join(new_resource.datadir, new_resource.appendfilename || "appendonly-#{resolved_instance_name}.aof")
  end

  def resolved_rdb_file
    ::File.join(new_resource.datadir, new_resource.dbfilename || "dump-#{resolved_instance_name}.rdb")
  end

  def limits_file
    "/etc/security/limits.d/redis-#{resolved_instance_name}.conf"
  end

  def config_path
    ::File.join(resolved_configdir, "#{resolved_instance_name}.conf")
  end

  def breadcrumb_path
    "#{config_path}.breadcrumb"
  end

  def service_name
    redis_service_name(resolved_instance_name)
  end
end

action :create do
  secrets = resolved_data_bag_secret

  user resolved_user do
    comment 'Redis service account'
    manage_home true
    home resolved_homedir
    shell resolved_shell
    system new_resource.systemuser
    uid new_resource.uid unless new_resource.uid.nil?
  end

  directory resolved_configdir do
    owner 'root'
    group resolved_group
    mode '0775'
    recursive true
  end

  directory new_resource.datadir do
    owner resolved_user
    group resolved_group
    mode '0775'
    recursive true
  end

  directory resolved_piddir do
    owner resolved_user
    group resolved_group
    mode '0755'
    recursive true
  end

  unless resolved_log_directory.nil?
    directory resolved_log_directory do
      owner resolved_user
      group resolved_group
      mode '0755'
      recursive true
    end
  end

  if selinux_enabled?
    selinux_install 'install'

    selinux_fcontext "#{resolved_configdir}(/.*)?" do
      secontext 'redis_conf_t'
    end

    selinux_fcontext "#{new_resource.datadir}(/.*)?" do
      secontext 'redis_var_lib_t'
    end

    selinux_fcontext "#{resolved_piddir}(/.*)?" do
      secontext 'redis_var_run_t'
    end

    unless resolved_log_directory.nil?
      selinux_fcontext "#{resolved_log_directory}(/.*)?" do
        secontext 'redis_log_t'
      end
    end
  end

  unless resolved_log_file.nil?
    file resolved_log_file do
      owner resolved_user
      group resolved_group
      mode '0644'
      backup false
      action :create
    end
  end

  file resolved_append_file do
    owner resolved_user
    group resolved_group
    mode '0644'
    only_if { %w(aof both).include?(new_resource.backuptype) && ::File.exist?(resolved_append_file) }
  end

  file resolved_rdb_file do
    owner resolved_user
    group resolved_group
    mode '0644'
    only_if { %w(rdb both).include?(new_resource.backuptype) && ::File.exist?(resolved_rdb_file) }
  end

  file limits_file do
    content <<~LIMITS
      #{resolved_user} soft nofile #{resolved_descriptors}
      #{resolved_user} hard nofile #{resolved_descriptors}
    LIMITS
    mode '0644'
  end

  template config_path do
    cookbook new_resource.template_cookbook
    source new_resource.template_source
    owner resolved_user
    group resolved_group
    mode new_resource.permissions
    variables(
      version: resolved_version_hash,
      piddir: resolved_piddir,
      name: resolved_instance_name,
      job_control: 'systemd',
      port: new_resource.port,
      tcpbacklog: new_resource.tcpbacklog,
      address: new_resource.address,
      databases: new_resource.databases,
      backuptype: new_resource.backuptype,
      datadir: new_resource.datadir,
      unixsocket: new_resource.unixsocket,
      unixsocketperm: new_resource.unixsocketperm,
      timeout: new_resource.timeout,
      keepalive: new_resource.keepalive,
      loglevel: new_resource.loglevel,
      logfile: new_resource.logfile,
      syslogenabled: new_resource.syslogenabled,
      syslogfacility: new_resource.syslogfacility,
      save: resolved_save,
      stopwritesonbgsaveerror: new_resource.stopwritesonbgsaveerror,
      rdbcompression: new_resource.rdbcompression,
      rdbchecksum: new_resource.rdbchecksum,
      dbfilename: new_resource.dbfilename,
      replicaof: new_resource.replicaof,
      protected_mode: new_resource.protected_mode,
      masterauth: secrets.fetch(:masterauth, new_resource.masterauth),
      replicaservestaledata: new_resource.replicaservestaledata,
      replicareadonly: new_resource.replicareadonly,
      repldisklesssync: new_resource.repldisklesssync,
      repldisklesssyncdelay: new_resource.repldisklesssyncdelay,
      replpingreplicaperiod: new_resource.replpingreplicaperiod,
      repltimeout: new_resource.repltimeout,
      repldisabletcpnodelay: new_resource.repldisabletcpnodelay,
      replbacklogsize: new_resource.replbacklogsize,
      replbacklogttl: new_resource.replbacklogttl,
      replicapriority: new_resource.replicapriority,
      requirepass: secrets.fetch(:requirepass, new_resource.requirepass),
      rename_commands: new_resource.rename_commands,
      maxclients: new_resource.maxclients,
      maxmemory: resolved_maxmemory,
      maxmemorypolicy: new_resource.maxmemorypolicy,
      maxmemorysamples: new_resource.maxmemorysamples,
      appendfilename: new_resource.appendfilename,
      appendfsync: new_resource.appendfsync,
      noappendfsynconrewrite: new_resource.noappendfsynconrewrite,
      aofrewritepercentage: new_resource.aofrewritepercentage,
      aofrewriteminsize: new_resource.aofrewriteminsize,
      aofloadtruncated: new_resource.aofloadtruncated,
      luatimelimit: new_resource.luatimelimit,
      slowloglogslowerthan: new_resource.slowloglogslowerthan,
      slowlogmaxlen: new_resource.slowlogmaxlen,
      notifykeyspaceevents: new_resource.notifykeyspaceevents,
      hashmaxziplistentries: new_resource.hashmaxziplistentries,
      hashmaxziplistvalue: new_resource.hashmaxziplistvalue,
      setmaxintsetentries: new_resource.setmaxintsetentries,
      zsetmaxziplistentries: new_resource.zsetmaxziplistentries,
      zsetmaxziplistvalue: new_resource.zsetmaxziplistvalue,
      hllsparsemaxbytes: new_resource.hllsparsemaxbytes,
      activerehasing: new_resource.activerehasing,
      clientoutputbufferlimit: new_resource.clientoutputbufferlimit,
      hz: new_resource.hz,
      aofrewriteincrementalfsync: new_resource.aofrewriteincrementalfsync,
      clusterenabled: new_resource.clusterenabled,
      clusterconfigfile: new_resource.clusterconfigfile,
      clusternodetimeout: new_resource.clusternodetimeout,
      clusterport: new_resource.clusterport,
      includes: new_resource.includes,
      aclfile: new_resource.aclfile,
      minreplicastowrite: new_resource.minreplicastowrite,
      minreplicasmaxlag: new_resource.minreplicasmaxlag,
      tlsport: new_resource.tlsport,
      tlscertfile: new_resource.tlscertfile,
      tlskeyfile: new_resource.tlskeyfile,
      tlskeyfilepass: new_resource.tlskeyfilepass,
      tlsclientcertfile: new_resource.tlsclientcertfile,
      tlsclientkeyfile: new_resource.tlsclientkeyfile,
      tlsclientkeyfilepass: new_resource.tlsclientkeyfilepass,
      tlsdhparamsfile: new_resource.tlsdhparamsfile,
      tlscacertfile: new_resource.tlscacertfile,
      tlscacertdir: new_resource.tlscacertdir,
      tlsauthclients: new_resource.tlsauthclients,
      tlsreplication: new_resource.tlsreplication,
      tlscluster: new_resource.tlscluster,
      tlsprotocols: new_resource.tlsprotocols,
      tlsciphers: new_resource.tlsciphers,
      tlsciphersuites: new_resource.tlsciphersuites,
      tlspreferserverciphers: new_resource.tlspreferserverciphers,
      tlssessioncaching: new_resource.tlssessioncaching,
      tlssessioncachesize: new_resource.tlssessioncachesize,
      tlssessioncachetimeout: new_resource.tlssessioncachetimeout
    )
    not_if { new_resource.breadcrumb && ::File.exist?(breadcrumb_path) }
    notifies :restart, "service[#{service_name}]", :delayed
  end

  file breadcrumb_path do
    content 'This file prevents the Chef cookbook from overwriting the redis config more than once'
    action :create_if_missing
    only_if { new_resource.breadcrumb }
  end

  systemd_unit "#{service_name}.service" do
    content(
      Unit: {
        Description: "Redis (#{resolved_instance_name}) persistent key-value database",
        Wants: 'network-online.target',
        After: 'network-online.target',
      },
      Service: {
        Type: 'notify',
        ExecStart: "#{redis_server_binary(resolved_bin_path, package_install: new_resource.package_install, package_name: resolved_package_name)} #{config_path} --daemonize no",
        User: resolved_user,
        Group: resolved_group,
        LimitNOFILE: resolved_descriptors,
      },
      Install: {
        WantedBy: 'multi-user.target',
      }
    )
    action %i(create enable)
  end

  service service_name do
    action %i(enable start)
    supports status: true, restart: true
  end
end

action :delete do
  service service_name do
    action %i(stop disable)
    supports status: true, restart: true
    ignore_failure true
  end

  systemd_unit "#{service_name}.service" do
    action %i(disable delete)
  end

  file breadcrumb_path do
    action :delete
  end

  file config_path do
    action :delete
  end

  file limits_file do
    action :delete
  end

  unless resolved_log_file.nil?
    file resolved_log_file do
      action :delete
    end
  end

  directory resolved_piddir do
    recursive true
    action :delete
  end

  directory new_resource.datadir do
    recursive true
    action :delete
  end
end
