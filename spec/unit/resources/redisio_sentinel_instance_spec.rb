# frozen_string_literal: true

require 'spec_helper'

describe 'redisio_sentinel_instance' do
  step_into :redisio_sentinel_instance
  platform 'ubuntu', '24.04'

  before do
    version_output = 'Redis server v=7.4.8 sha=000:0 malloc=jemalloc-5.3.0 bits=64 build=00000000'

    stub_service_inactive('redis-sentinel@cluster')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/usr/bin/redis-server').and_return(true)
    allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out!).and_call_original
    allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out!)
      .with('/usr/bin/redis-server -v')
      .and_return(double(stdout: version_output))
  end

  recipe do
    redisio_sentinel_instance 'cluster' do
      package_install true
      sentinel_bind '0.0.0.0'
      masters [
        {
          master_name: 'master6379',
          master_ip: '127.0.0.1',
          master_port: 6379,
        },
      ]
    end
  end

  it { is_expected.to create_template('/etc/redis/sentinel_cluster.conf') }
  it { is_expected.to render_file('/etc/redis/sentinel_cluster.conf').with_content(/sentinel monitor master6379 127.0.0.1 6379 2/) }
  it { is_expected.to create_systemd_unit('redis-sentinel@cluster.service') }
  it { is_expected.to enable_service('redis-sentinel@cluster') }
  it { is_expected.to start_service('redis-sentinel@cluster') }

  context 'with a valkey package-backed sentinel' do
    before do
      version_output = 'Valkey server v=8.0.6 sha=00000000:1 malloc=jemalloc-5.3.0 bits=64 build=00000000'

      stub_service_inactive('valkey-sentinel@cluster')
      allow(File).to receive(:exist?).with('/usr/bin/valkey-server').and_return(true)
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out!)
        .with('/usr/bin/valkey-server -v')
        .and_return(double(stdout: version_output))
    end

    recipe do
      redisio_sentinel_instance 'cluster' do
        package_install true
        server_implementation 'valkey'
        masters [
          {
            master_name: 'master6379',
            master_ip: '127.0.0.1',
            master_port: 6379,
          },
        ]
      end
    end

    it { is_expected.to create_template('/etc/valkey/sentinel_cluster.conf') }
    it { is_expected.to create_systemd_unit('valkey-sentinel@cluster.service') }
    it { is_expected.to enable_service('valkey-sentinel@cluster') }
    it { is_expected.to start_service('valkey-sentinel@cluster') }
  end
end
