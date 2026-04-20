# frozen_string_literal: true

require 'spec_helper'

describe 'redisio_server' do
  step_into :redisio_server
  platform 'ubuntu', '24.04'

  before do
    version_output = 'Redis server v=7.4.8 sha=000:0 malloc=jemalloc-5.3.0 bits=64 build=00000000'

    stub_service_inactive('redis@6379')
    stub_service_inactive('redis@savetest')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/usr/bin/redis-server').and_return(true)
    allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out!).and_call_original
    allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out!)
      .with('/usr/bin/redis-server -v')
      .and_return(double(stdout: version_output))
  end

  context 'with a default server instance' do
    recipe do
      redisio_server '6379' do
        package_install true
      end
    end

    it { is_expected.to create_directory('/etc/redis') }
    it { is_expected.to create_template('/etc/redis/6379.conf') }
    it { is_expected.to create_systemd_unit('redis@6379.service') }
    it { is_expected.to enable_service('redis@6379') }
    it { is_expected.to start_service('redis@6379') }
  end

  context 'with a named secondary instance' do
    recipe do
      redisio_server 'savetest' do
        package_install true
        port 16_379
        permissions '0640'
        save ['3600 1', '300 100', '60 10000']
        logfile '/var/log/redis/redis-16379.log'
      end
    end

    it { is_expected.to create_template('/etc/redis/savetest.conf').with(mode: '0640') }
    it { is_expected.to render_file('/etc/redis/savetest.conf').with_content(/save 3600 1/) }
    it { is_expected.to render_file('/etc/redis/savetest.conf').with_content(/save 300 100/) }
    it { is_expected.to render_file('/etc/redis/savetest.conf').with_content(/save 60 10000/) }
    it { is_expected.to create_file('/var/log/redis/redis-16379.log') }
  end
end
