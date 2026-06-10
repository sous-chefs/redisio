# frozen_string_literal: true

provides :redisio_sentinel_instance
unified_mode true

use '_partial/_base'

property :instance_name, String, name_property: true
property :name_override, String
property :sentinel_bind, [String, Array, nil], default: nil
property :sentinel_port, [String, Integer], default: 26_379
property :masters, Array, default: []
property :master_name, String
property :master_ip, String
property :master_port, [String, Integer, nil], default: nil
property :quorum_count, [String, Integer], default: 2
property :auth_pass, String
property :down_after_milliseconds, [String, Integer], default: 30_000
property :parallel_syncs, [String, Integer], default: 1
property :failover_timeout, [String, Integer], default: 900_000
property :announce_ip, String
property :announce_port, [String, Integer, nil], default: nil
property :notification_script, String
property :client_reconfig_script, String

action_class do
  include RedisioCookbook::Helpers

  def resolved_user
    new_resource.user
  end

  def resolved_instance_name
    (new_resource.name_override || new_resource.instance_name).to_s
  end

  def resolved_group
    new_resource.group || platform_default_group(server_implementation: new_resource.server_implementation)
  end

  def resolved_homedir
    new_resource.homedir || platform_default_home(server_implementation: new_resource.server_implementation)
  end

  def resolved_shell
    new_resource.shell || platform_default_shell
  end

  def resolved_configdir
    new_resource.configdir || platform_default_config_dir(server_implementation: new_resource.server_implementation)
  end

  def resolved_bin_path
    new_resource.bin_path || platform_default_bin_path(package_install: new_resource.package_install, install_dir: new_resource.install_dir)
  end

  def resolved_package_name
    new_resource.package_name || platform_package_name(server_implementation: new_resource.server_implementation)
  end

  def resolved_version_hash
    version = if new_resource.version
                new_resource.version
              elsif new_resource.package_install
                '7.0.0'
              else
                installed_redis_version(
                  resolved_bin_path,
                  package_install: new_resource.package_install,
                  package_name: resolved_package_name,
                  server_implementation: new_resource.server_implementation
                )
              end

    redis_version_to_hash(version || '0.0.0')
  end

  def resolved_config_name
    sentinel_config_name(resolved_instance_name)
  end

  def resolved_piddir
    ::File.join(new_resource.base_piddir, resolved_config_name)
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

  def base_master
    {
      'master_name' => new_resource.master_name,
      'master_ip' => new_resource.master_ip,
      'master_port' => new_resource.master_port,
      'quorum_count' => new_resource.quorum_count,
      'auth_pass' => new_resource.auth_pass,
      'down_after_milliseconds' => new_resource.down_after_milliseconds,
      'parallel_syncs' => new_resource.parallel_syncs,
      'failover_timeout' => new_resource.failover_timeout,
    }
  end

  def resolved_masters
    masters = normalize_array(new_resource.masters).map { |master| deep_stringify_keys(normalize_hash(master)) }
    masters = [base_master] if masters.empty? && new_resource.master_ip
    raise 'At least one sentinel master must be defined' if masters.empty?

    bag_secret = if new_resource.data_bag_name && new_resource.data_bag_item && new_resource.data_bag_key
                   data_bag_item(new_resource.data_bag_name, new_resource.data_bag_item)[new_resource.data_bag_key]
                 end

    masters.map do |master|
      {
        'master_name' => master['master_name'] || master['name'],
        'master_ip' => master['master_ip'],
        'master_port' => master['master_port'],
        'quorum_count' => master['quorum_count'].nil? ? new_resource.quorum_count : master['quorum_count'],
        'auth_pass' => bag_secret || master['auth_pass'],
        'down_after_milliseconds' => master['down_after_milliseconds'].nil? ? new_resource.down_after_milliseconds : master['down_after_milliseconds'],
        'parallel_syncs' => master['parallel_syncs'].nil? ? new_resource.parallel_syncs : master['parallel_syncs'],
        'failover_timeout' => master['failover_timeout'].nil? ? new_resource.failover_timeout : master['failover_timeout'],
      }.tap do |resolved|
        %w(master_name master_ip master_port quorum_count).each do |key|
          raise "Missing required sentinel parameter #{key}" if resolved[key].nil?
        end
      end
    end
  end

  def config_path
    ::File.join(resolved_configdir, "#{resolved_config_name}.conf")
  end

  def breadcrumb_path
    "#{config_path}.breadcrumb"
  end

  def service_name
    sentinel_service_name(resolved_instance_name, server_implementation: new_resource.server_implementation)
  end

  def implementation_name
    new_resource.server_implementation == 'valkey' ? 'Valkey Sentinel' : 'Redis Sentinel'
  end
end

action :create do
  validate_server_implementation!(
    package_install: new_resource.package_install,
    server_implementation: new_resource.server_implementation
  )

  user new_resource.user do
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

  unless resolved_log_file.nil?
    file resolved_log_file do
      owner resolved_user
      group resolved_group
      mode '0644'
      backup false
      action :create
    end
  end

  template config_path do
    source 'sentinel.conf.erb'
    cookbook 'redisio'
    owner resolved_user
    group resolved_group
    mode '0644'
    variables(
      name: resolved_instance_name,
      piddir: resolved_piddir,
      version: resolved_version_hash,
      job_control: 'systemd',
      sentinel_bind: new_resource.sentinel_bind,
      sentinel_port: new_resource.sentinel_port,
      loglevel: new_resource.loglevel,
      logfile: new_resource.logfile,
      syslogenabled: new_resource.syslogenabled,
      syslogfacility: new_resource.syslogfacility,
      masters: resolved_masters,
      announce_ip: new_resource.announce_ip,
      announce_port: new_resource.announce_port,
      notification_script: new_resource.notification_script,
      client_reconfig_script: new_resource.client_reconfig_script,
      protected_mode: new_resource.protected_mode,
      maxclients: new_resource.maxclients,
      aclfile: new_resource.aclfile,
      includes: new_resource.includes,
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
    not_if { ::File.exist?(breadcrumb_path) }
    notifies :restart, "service[#{service_name}]", :delayed
  end

  file breadcrumb_path do
    content 'This file prevents the Chef cookbook from overwriting the sentinel config more than once'
    action :create_if_missing
  end

  systemd_unit "#{service_name}.service" do
    content(
      Unit: {
        Description: "#{implementation_name} (#{resolved_instance_name})",
        After: 'network.target',
      },
      Service: {
        Type: 'notify',
        ExecStart: "#{redis_server_binary(
          resolved_bin_path,
          package_install: new_resource.package_install,
          package_name: resolved_package_name,
          server_implementation: new_resource.server_implementation
        )} #{config_path} --sentinel --daemonize no",
        User: resolved_user,
        Group: resolved_group,
        LimitNOFILE: new_resource.maxclients + 32,
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
  validate_server_implementation!(
    package_install: new_resource.package_install,
    server_implementation: new_resource.server_implementation
  )

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

  unless resolved_log_file.nil?
    file resolved_log_file do
      action :delete
    end
  end

  directory resolved_piddir do
    recursive true
    action :delete
  end
end
