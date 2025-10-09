action :run do
  base_piddir = new_resource.base_piddir

  current_version = if new_resource.version.nil?
                      version
                    else
                      new_resource.version
                    end

  version_hash = RedisioHelper.version_to_hash(current_version)

  # Setup a configuration file and init script for each configuration provided
  new_resource.sentinels.each do |current_instance|
    # Retrieve the default settings hash and the current server setups settings hash.
    current_instance_hash = current_instance.to_hash
    current_defaults_hash = new_resource.sentinel_defaults.to_hash

    # Merge the configuration defaults with the provided array of configurations provided
    current = current_defaults_hash.merge(current_instance_hash)

    sentinel_name = current['name'] || current['port']
    sentinel_name = "sentinel_#{sentinel_name}"
    piddir = "#{base_piddir}/#{sentinel_name}"

    # Create the owner of the redis data directory
    user current['user'] do
      comment 'Redis service account'
      manage_home true
      home current['homedir']
      shell current['shell']
      system current['systemuser']
      uid current['uid'] unless current['uid'].nil?
    end

    # Create the redis configuration directory
    directory current['configdir'] do
      owner 'root'
      group platform_family?('freebsd') ? 'wheel' : 'redis'
      mode '0775'
      recursive true
      action :create
    end
    # Create the pid file directory
    directory piddir do
      owner current['user']
      group current['group']
      mode '0755'
      recursive true
      action :create
    end

    unless current['logfile'].nil?
      # Create the log directory if syslog is not being used
      directory ::File.dirname(current['logfile']) do
        owner current['user']
        group current['group']
        mode '0755'
        recursive true
        action :create
        only_if { current['syslogenabled'] != 'yes' && current['logfile'] && current['logfile'] != 'stdout' }
      end

      # Create the log file is syslog is not being used
      file current['logfile'] do
        owner current['user']
        group current['group']
        mode '0644'
        backup false
        action :touch
        only_if { current['logfile'] && current['logfile'] != 'stdout' }
      end
    end

    # <%=@name%> <%=@masterip%> <%=@masterport%> <%= @quorum_count %>
    # <%= "sentinel auth-pass #{@name} #{@authpass}" unless @authpass.nil? %>
    # sentinel down-after-milliseconds <%=@name%> <%=@downaftermil%>
    # sentinel parallel-syncs <%=@name%> <%=@parallelsyncs%>
    # sentinel failover-timeout <%=@name%> <%=@failovertimeout%>

    # convert from old format (preserve compat)
    if !current['masters'] && current['master_ip']
      Chef::Log.warn('You are using a deprecated sentinel format. This will be removed in future versions.')

      # use old key names if newer key names aren't present (e.g. 'foo' || :foo)
      masters = [
        {
          master_name: current['master_name'] || current[:mastername],
          master_ip: current['master_ip'] || current[:masterip],
          master_port: current['master_port'] || current[:masterport],
          quorum_count: current['quorum_count'] || current[:quorum_count],
          auth_pass: current['auth-pass'] || current[:authpass],
          down_after_milliseconds: current['down-after-milliseconds'] || current[:downaftermil],
          parallel_syncs: current['parallel-syncs'] || current[:parallelsyncs],
          failover_timeout: current['failover-timeout'] || current[:failovertimeout],
        },
      ]
    else
      masters = [current['masters']].flatten
    end

    # Load password for use with requirepass from data bag if needed
    if current['data_bag_name'] && current['data_bag_item'] && current['data_bag_key']
      bag = data_bag_item(current['data_bag_name'], current['data_bag_item'])
      masters.each do |master|
        master['auth_pass'] = bag[current['data_bag_key']]
      end
    end

    # merge in default values to each sentinel hash
    masters_with_defaults = []
    masters.each do |current_sentinel_master|
      default_sentinel_master = new_resource.sentinel_defaults.to_hash
      sentinel_master = default_sentinel_master.merge(current_sentinel_master || {})
      masters_with_defaults << sentinel_master
    end

    # Don't render a template if we're missing these from any sentinel,
    # as these are the minimal settings required to be passed in
    masters_with_defaults.each do |sentinel_instance|
      %w(master_ip master_port quorum_count).each do |param|
        raise "Missing required sentinel parameter #{param} for #{sentinel_instance}" unless sentinel_instance[param]
      end
    end

    # Lay down the configuration files for the current instance
    template "#{current['configdir']}/#{sentinel_name}.conf" do
      source 'sentinel.conf.erb'
      cookbook 'redisio'
      owner current['user']
      group current['group']
      mode '0644'
      action :create
      variables(
        name: current['name'],
        piddir: piddir,
        version: version_hash,
        job_control: node['redisio']['job_control'],
        sentinel_bind: current['sentinel_bind'],
        sentinel_port: current['sentinel_port'],
        loglevel: current['loglevel'],
        logfile: current['logfile'],
        syslogenabled: current['syslogenabled'],
        syslogfacility: current['syslogfacility'],
        masters: masters_with_defaults,
        announce_ip: current['announce-ip'],
        announce_port: current['announce-port'],
        notification_script: current['notification-script'],
        client_reconfig_script: current['client-reconfig-script'],
        protected_mode: current['protected_mode'],
        maxclients: current['maxclients'],
        aclfile: current['aclfile'],
        includes: current['includes'],
        tlsport: current['tlsport'],
        tlscertfile: current['tlscertfile'],
        tlskeyfile: current['tlskeyfile'],
        tlskeyfilepass: current['tlskeyfilepass'],
        tlsclientcertfile: current['tlsclientcertfile'],
        tlsclientkeyfile: current['tlsclientkeyfile'],
        tlsclientkeyfilepass: current['tlsclientkeyfilepass'],
        tlsdhparamsfile: current['tlsdhparamsfile'],
        tlscacertfile: current['tlscacertfile'],
        tlscacertdir: current['tlscacertdir'],
        tlsauthclients: current['tlsauthclients'],
        tlsreplication: current['tlsreplication'],
        tlscluster: current['tlscluster'],
        tlsprotocols: current['tlsprotocols'],
        tlsciphers: current['tlsciphers'],
        tlsciphersuites: current['tlsciphersuites'],
        tlspreferserverciphers: current['tlspreferserverciphers'],
        tlssessioncaching: current['tlssessioncaching'],
        tlssessioncachesize: current['tlssessioncachesize'],
        tlssessioncachetimeout: current['tlssessioncachetimeout']
      )
      not_if { ::File.exist?("#{current['configdir']}/#{sentinel_name}.conf.breadcrumb") }
    end

    file "#{current['configdir']}/#{sentinel_name}.conf.breadcrumb" do
      content 'This file prevents the chef cookbook from overwritting the sentinel config more than once'
      action :create_if_missing
    end

    # Setup init.d file
    bin_path = if node['redisio']['install_dir']
                 ::File.join(node['redisio']['install_dir'], 'bin')
               else
                 node['redisio']['bin_path']
               end
    template "/etc/init.d/redis_#{sentinel_name}" do
      source 'sentinel.init.erb'
      cookbook 'redisio'
      owner 'root'
      group 'root'
      mode '0755'
      variables(
        name: sentinel_name,
        bin_path: bin_path,
        user: current['user'],
        configdir: current['configdir'],
        piddir: piddir,
        platform: node['platform']
      )
      only_if { node['redisio']['job_control'] == 'initd' }
    end

    template "/etc/init/redis_#{sentinel_name}.conf" do
      source 'sentinel.upstart.conf.erb'
      cookbook 'redisio'
      owner current['user']
      group current['group']
      mode '0644'
      variables(
        name: sentinel_name,
        bin_path: bin_path,
        user: current['user'],
        group: current['group'],
        configdir: current['configdir'],
        piddir: piddir
      )
      only_if { node['redisio']['job_control'] == 'upstart' }
    end
    # TODO: fix for freebsd
    template "/usr/local/etc/rc.d/redis_#{sentinel_name}" do
      source 'sentinel.rcinit.erb'
      cookbook 'redisio'
      owner current['user']
      group current['group']
      mode '0755'
      variables(
        name: sentinel_name,
        bin_path: bin_path,
        user: current['user'],
        configdir: current['configdir'],
        piddir: piddir
      )
      only_if { node['redisio']['job_control'] == 'rcinit' }
    end
  end
  # servers each loop
end

def redis_exists?
  bin_path = if node['redisio']['install_dir']
               ::File.join(node['redisio']['install_dir'], 'bin')
             else
               node['redisio']['bin_path']
             end
  redis_server = ::File.join(bin_path, 'redis-server')
  ::File.exist?(redis_server)
end

def version
  if redis_exists?
    bin_path = if node['redisio']['install_dir']
                 ::File.join(node['redisio']['install_dir'], 'bin')
               else
                 node['redisio']['bin_path']
               end
    redis_server = ::File.join(bin_path, 'redis-server')
    redis_version = Mixlib::ShellOut.new("#{redis_server} -v")
    redis_version.run_command
    version = redis_version.stdout[/version (\d*.\d*.\d*)/, 1] || redis_version.stdout[/v=(\d*.\d*.\d*)/, 1]
    Chef::Log.info("The Redis server version is: #{version}")
    return version.delete("\n")
  end
  nil
end
