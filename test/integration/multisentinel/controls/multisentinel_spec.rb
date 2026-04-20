# frozen_string_literal: true

require_relative '../../spec_helper'

control 'redisio-multisentinel-service-01' do
  impact 1.0
  title 'The multi-sentinel service is enabled and running'

  describe systemd_service(redis_sentinel_service_name('cluster')) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'redisio-multisentinel-port-01' do
  impact 0.7
  title 'The sentinel port is listening'

  describe port(26_379) do
    it { should be_listening }
  end
end

control 'redisio-multisentinel-config-01' do
  impact 0.7
  title 'The sentinel config contains both monitored masters'

  describe file('/etc/redis/sentinel_cluster.conf') do
    it { should exist }
    its('content') { should match(/sentinel monitor master6379 127.0.0.1 6379 2/) }
    its('content') { should match(/sentinel monitor master6380 127.0.0.1 6380 2/) }
  end
end

control 'redisio-multisentinel-runtime-01' do
  impact 0.5
  title 'The sentinel reports both masters'

  describe command("#{redis_cli_binary} --raw -p 26379 SENTINEL MASTER master6379") do
    its('stdout') { should match(/master6379/) }
    its('stdout') { should match(/127.0.0.1/) }
    its('stdout') { should match(/6379/) }
    its('stdout') { should match(/down-after-milliseconds/) }
    its('stdout') { should match(/30000/) }
    its('stdout') { should match(/parallel-syncs/) }
    its('stdout') { should match(/\n1\n/) }
    its('stdout') { should match(/failover-timeout/) }
    its('stdout') { should match(/900000/) }
  end

  describe command("#{redis_cli_binary} --raw -p 26379 SENTINEL MASTER master6380") do
    its('stdout') { should match(/master6380/) }
    its('stdout') { should match(/127.0.0.1/) }
    its('stdout') { should match(/6380/) }
    its('stdout') { should match(/down-after-milliseconds/) }
    its('stdout') { should match(/30000/) }
    its('stdout') { should match(/parallel-syncs/) }
    its('stdout') { should match(/\n1\n/) }
    its('stdout') { should match(/failover-timeout/) }
    its('stdout') { should match(/900000/) }
  end
end
