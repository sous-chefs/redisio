# frozen_string_literal: true

provides :redisio_sentinel
unified_mode true

property :version, [String, NilClass]
property :base_piddir, String, default: '/var/run/redis'
property :user, String, default: 'redis'
property :group, String, default: 'redis'
property :sentinel_defaults, Hash, default: {}
property :sentinels, [Array, NilClass], default: nil
property :package_install, [true, false], default: false
property :package_name, [String, NilClass]
property :install_dir, [String, NilClass]
property :bin_path, [String, NilClass]

action_class do
  include RedisioCookbook::Helpers

  SENTINEL_KEY_MAP = {
    'announce-ip' => 'announce_ip',
    'announce-port' => 'announce_port',
    'notification-script' => 'notification_script',
    'client-reconfig-script' => 'client_reconfig_script',
  }.freeze

  MASTER_KEY_MAP = {
    'auth-pass' => 'auth_pass',
    'down-after-milliseconds' => 'down_after_milliseconds',
    'parallel-syncs' => 'parallel_syncs',
    'failover-timeout' => 'failover_timeout',
  }.freeze

  def normalized_sentinels
    return [
      {
        'sentinel_port' => 26_379,
        'name' => 'mycluster',
        'masters' => [
          {
            'master_name' => 'mycluster_master',
            'master_ip' => '127.0.0.1',
            'master_port' => 6379,
          },
        ],
      },
    ] if new_resource.sentinels.nil?

    normalize_array(new_resource.sentinels).map { |sentinel| deep_stringify_keys(normalize_hash(sentinel)) }
  end

  def normalize_sentinel_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      mapped_key = SENTINEL_KEY_MAP.fetch(key, key)
      result[mapped_key] = value
    end
  end

  def normalize_master_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      mapped_key = MASTER_KEY_MAP.fetch(key, key)
      result[mapped_key] = value
    end
  end
end

action :create do
  defaults = normalize_sentinel_keys(deep_stringify_keys(normalize_hash(new_resource.sentinel_defaults)))

  normalized_sentinels.each do |sentinel|
    merged = defaults.merge(normalize_sentinel_keys(sentinel))
    instance_name = (merged['name'] || merged['sentinel_port']).to_s
    masters = normalize_array(merged['masters']).map { |master| normalize_master_keys(deep_stringify_keys(normalize_hash(master))) }
    if masters.empty? && merged['master_ip']
      masters = [
        {
          'master_name' => merged['master_name'] || merged['mastername'],
          'master_ip' => merged['master_ip'],
          'master_port' => merged['master_port'],
          'quorum_count' => merged['quorum_count'],
          'auth_pass' => merged['auth_pass'] || merged['authpass'],
          'down_after_milliseconds' => merged['down_after_milliseconds'] || merged['downaftermil'],
          'parallel_syncs' => merged['parallel_syncs'] || merged['parallelsyncs'],
          'failover_timeout' => merged['failover_timeout'] || merged['failovertimeout'],
        },
      ]
    end

    redisio_sentinel_instance instance_name do
      version new_resource.version || merged['version']
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
      name_override merged['name']
      sentinel_bind merged['sentinel_bind']
      sentinel_port merged.fetch('sentinel_port', 26_379)
      masters masters
      master_name merged['master_name']
      master_ip merged['master_ip']
      master_port merged['master_port']
      quorum_count merged.fetch('quorum_count', 2)
      auth_pass merged['auth_pass']
      down_after_milliseconds merged.fetch('down_after_milliseconds', 30_000)
      parallel_syncs merged.fetch('parallel_syncs', 1)
      failover_timeout merged.fetch('failover_timeout', 900_000)
      announce_ip merged['announce_ip']
      announce_port merged['announce_port']
      notification_script merged['notification_script']
      client_reconfig_script merged['client_reconfig_script']
      action new_resource.action
    end
  end
end
