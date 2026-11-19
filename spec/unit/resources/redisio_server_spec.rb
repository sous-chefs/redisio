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
    it 'keeps readiness notifications for package installations' do
      unit = chef_run.systemd_unit('redis@6379.service')
      expect(unit.content[:Service]).to include(Type: 'notify')
      expect(unit.content[:Service][:ExecStart]).to end_with('--daemonize no')
    end

    it { is_expected.to create_systemd_unit('redis@6379.service') }
    it { is_expected.to enable_service('redis@6379') }
    it { is_expected.to start_service('redis@6379') }
  end

  context 'with an existing breadcrumb' do
    let(:config_path) { '/etc/redis/6379.conf' }
    let(:breadcrumb_path) { "#{config_path}.breadcrumb" }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:exist?).with(config_path).and_return(true)
    end

    [
      'This file prevents the Chef cookbook from overwriting the redis config more than once',
      'This file prevents the chef cookbook from overwritting the redis config more than once',
    ].each do |legacy_marker|
      it "preserves the configuration while migrating #{legacy_marker.inspect}" do
        allow(File).to receive(:read).with(breadcrumb_path).and_return(legacy_marker)

        run = converge_server
        expect(run).not_to create_template(config_path)
        expect(run).to create_file(breadcrumb_path).with(content: /\A[0-9a-f]{64}\z/, mode: '0600')
      end
    end

    it 'renders a changed desired configuration and preserves it on subsequent runs' do
      allow(File).to receive(:read).with(breadcrumb_path).and_raise(Errno::ENOENT)
      previous_run = converge_server
      allow(File).to receive(:read).with(breadcrumb_path).and_return(previous_run.file(breadcrumb_path).content)

      expect(converge_server).not_to create_template(config_path)

      updated_run = converge_server(maxclients: 5000)
      expect(updated_run).to create_template(config_path)
      expect(updated_run).to render_file(config_path).with_content(/^maxclients 5000$/)
      expect(updated_run.template(config_path)).to notify('service[redis@6379]').to(:restart).delayed
      expect(updated_run.file(breadcrumb_path).content).not_to eq(previous_run.file(breadcrumb_path).content)
    end

    it 'recreates a missing configuration' do
      allow(File).to receive(:read).with(breadcrumb_path).and_raise(Errno::ENOENT)
      previous_run = converge_server
      allow(File).to receive(:read).with(breadcrumb_path).and_return(previous_run.file(breadcrumb_path).content)
      allow(File).to receive(:exist?).with(config_path).and_return(false)

      expect(converge_server).to create_template(config_path)
    end

    it 'applies the configuration when breadcrumb protection is disabled' do
      allow(File).to receive(:read).with(breadcrumb_path)
                                   .and_return('This file prevents the Chef cookbook from overwriting the redis config more than once')

      run = converge_server(breadcrumb: false)
      expect(run).to create_template(config_path)
      expect(run).not_to create_file(breadcrumb_path)
    end

    def converge_server(maxclients: 10_000, breadcrumb: true)
      chef_runner_instance.converge_block do
        redisio_server '6379' do
          package_install true
          maxclients maxclients
          breadcrumb breadcrumb
        end
      end
    end
  end

  context 'with SELinux enabled and a custom source installation' do
    platform 'rocky', '9'

    before do
      allow_any_instance_of(Chef::Util::Selinux).to receive(:selinux_enabled?).and_return(true)
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out).and_call_original
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out)
        .with('matchpathcon', '-V', '/opt/redis/bin/redis-server')
        .and_return(double(exitstatus: 1))
    end

    recipe do
      redisio_server '6379' do
        install_dir '/opt/redis'
        version '7.4.8'
      end
    end

    it 'starts a foreground source build without waiting for a readiness notification' do
      unit = chef_run.systemd_unit('redis@6379.service')
      expect(unit.content[:Service]).to include(Type: 'simple')
      expect(unit.content[:Service][:ExecStart]).to end_with('--daemonize no --supervised no')
    end

    it 'labels the executable before starting the service' do
      expect(chef_run.find_resource(:selinux_fcontext, Regexp.escape('/opt/redis/bin/redis-server')).secontext).to eq('redis_exec_t')
      expect(chef_run).to run_execute('restore Redis executable context for /opt/redis/bin/redis-server')
      expect(chef_run.execute('restore Redis executable context for /opt/redis/bin/redis-server')).to notify('service[redis@6379]').to(:restart).delayed
    end
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
