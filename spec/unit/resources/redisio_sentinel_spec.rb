# frozen_string_literal: true

require 'spec_helper'

describe 'redisio_sentinel' do
  step_into :redisio_sentinel, :redisio_sentinel_instance
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
    redisio_sentinel 'default' do
      package_install true
      sentinels(
        [
          {
            'name' => 'cluster',
            'master_ip' => '127.0.0.1',
            'master_port' => 6379,
            'master_name' => 'master6379',
          },
        ]
      )
    end
  end

  it { is_expected.to create_template('/etc/redis/sentinel_cluster.conf') }
  it { is_expected.to render_file('/etc/redis/sentinel_cluster.conf').with_content(/sentinel monitor master6379 127.0.0.1 6379 2/) }
end
