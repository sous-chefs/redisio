# frozen_string_literal: true

require_relative '../../spec_helper'

control 'redisio-default-package-01' do
  impact 1.0
  title 'The Redis package is installed'

  describe package(redis_package_name) do
    it { should be_installed }
  end
end

control 'redisio-default-service-01' do
  impact 1.0
  title 'The primary Redis service is enabled and running'

  describe systemd_service(redis_service_name('6379')) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'redisio-default-port-01' do
  impact 0.7
  title 'The primary Redis port is listening'

  describe port(6379) do
    it { should be_listening }
  end
end

control 'redisio-default-config-01' do
  impact 0.7
  title 'The named secondary instance config exists'

  describe file('/etc/redis/savetest.conf') do
    it { should exist }
    its('mode') { should cmp '0640' }
    its('content') { should match(/save 3600 1/) }
    its('content') { should match(/save 300 100/) }
    its('content') { should match(/save 60 10000/) }
  end
end

control 'redisio-default-selinux-01' do
  impact 0.3
  title 'SELinux contexts are configured when semanage is present'
  only_if('semanage is installed') { command('command -v semanage').exit_status.zero? }

  describe command('semanage fcontext --list --noheading | grep -F redis') do
    its('stdout') { should match(%r{^/etc/redis\(/\.\*\)\?\s.*:redis_conf_t:}) }
    its('stdout') { should match(%r{^/var/lib/redis\(/\.\*\)\?\s.*:redis_var_lib_t:}) }
    its('stdout') { should match(%r{^/var/run/redis/6379\(/\.\*\)\?\s.*:redis_var_run_t:}) }
  end
end
