# frozen_string_literal: true

property :name_override, default: nil
property :sentinel_bind, default: nil
property :sentinel_port, [String, Integer], default: 26_379
property :masters, Array, default: []
property :master_name, default: nil
property :master_ip, default: nil
property :master_port, default: nil
property :quorum_count, default: 2
property :auth_pass, default: nil
property :down_after_milliseconds, default: 30_000
property :parallel_syncs, default: 1
property :failover_timeout, default: 900_000
property :announce_ip, default: nil
property :announce_port, default: nil
property :notification_script, default: nil
property :client_reconfig_script, default: nil
