# frozen_string_literal: true

require 'spec_helper'

describe 'redisio_install' do
  step_into :redisio_install

  context 'with package install on ubuntu' do
    platform 'ubuntu', '24.04'

    recipe do
      redisio_install 'default' do
        package_install true
      end
    end

    it { is_expected.to install_package('redis-server') }
    it { is_expected.to disable_service('redis-server') }
    it { is_expected.to stop_service('redis-server') }
  end

  context 'with package install on amazon linux 2023' do
    platform 'amazon', '2023'

    recipe do
      redisio_install 'default' do
        package_install true
      end
    end

    it { is_expected.to install_package('redis6') }
    it { is_expected.to disable_service('redis6') }
  end

  context 'with source install' do
    platform 'ubuntu', '24.04'

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/usr/local/bin/redis-server').and_return(false)
    end

    recipe do
      redisio_install 'default' do
        version '7.4.8'
      end
    end

    it { is_expected.to install_package('gcc') }
    it { is_expected.to create_remote_file("#{Chef::Config[:file_cache_path]}/redis-7.4.8.tar.gz") }
    it { is_expected.to run_execute('build-redis-7.4.8') }
    it { is_expected.to run_execute('install-redis-7.4.8') }
  end
end
