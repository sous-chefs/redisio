# frozen_string_literal: true

require 'spec_helper'

describe 'redisio_configure' do
  step_into :redisio_configure, :redisio_server
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

  context 'with nil servers' do
    recipe do
      redisio_configure 'default' do
        package_install true
      end
    end

    it { is_expected.to create_template('/etc/redis/6379.conf') }
    it { is_expected.to enable_service('redis@6379') }
  end

  context 'with a named server in the wrapper payload' do
    recipe do
      redisio_configure 'default' do
        package_install true
        default_settings('permissions' => '0644')
        servers(
          [
            {
              'name' => 'savetest',
              'port' => 16_379,
              'permissions' => '0640',
            },
          ]
        )
      end
    end

    it { is_expected.to create_template('/etc/redis/savetest.conf').with(mode: '0640') }
  end
end
