# frozen_string_literal: true

property :version
property :base_piddir, String, default: '/var/run/redis'
property :user, String, default: 'redis'
property :group, String, default: 'redis'
property :uid
property :systemuser, [true, false], default: true
property :homedir
property :shell
property :configdir
property :loglevel, String, default: 'notice'
property :logfile, default: nil
property :syslogenabled, String, default: 'yes'
property :syslogfacility, String, default: 'local0'
property :protected_mode, default: nil
property :maxclients, Integer, default: 10_000
property :aclfile, default: nil
property :includes, default: nil
property :data_bag_name, default: nil
property :data_bag_item, default: nil
property :data_bag_key, default: nil
property :tlsport, default: nil
property :tlscertfile, default: nil
property :tlskeyfile, default: nil
property :tlskeyfilepass, default: nil
property :tlsclientcertfile, default: nil
property :tlsclientkeyfile, default: nil
property :tlsclientkeyfilepass, default: nil
property :tlsdhparamsfile, default: nil
property :tlscacertfile, default: nil
property :tlscacertdir, default: nil
property :tlsauthclients, default: nil
property :tlsreplication, default: nil
property :tlscluster, default: nil
property :tlsprotocols, default: nil
property :tlsciphers, default: nil
property :tlsciphersuites, default: nil
property :tlspreferserverciphers, default: nil
property :tlssessioncaching, default: nil
property :tlssessioncachesize, default: nil
property :tlssessioncachetimeout, default: nil
property :package_install, [true, false], default: false, desired_state: false
property :package_name
property :install_dir, default: nil
property :bin_path
