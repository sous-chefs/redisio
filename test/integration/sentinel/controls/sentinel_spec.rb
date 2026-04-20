# frozen_string_literal: true

require_relative '../../spec_helper'

control 'redisio-sentinel-service-01' do
  impact 1.0
  title 'The sentinel service is enabled and running'

  describe systemd_service(redis_sentinel_service_name('mycluster')) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'redisio-sentinel-port-01' do
  impact 0.7
  title 'The sentinel port is listening'

  describe port(26_379) do
    it { should be_listening }
  end
end

control 'redisio-sentinel-config-01' do
  impact 0.5
  title 'The sentinel config contains the monitored master'

  describe file('/etc/redis/sentinel_mycluster.conf') do
    it { should exist }
    its('content') { should match(/sentinel monitor mycluster_master 127.0.0.1 6379 2/) }
  end
end
