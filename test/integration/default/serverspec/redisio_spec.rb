require 'spec_helper'

describe 'Redis' do

  it 'enables the redis service' do
    expect(service 'redis6379').to be_enabled
  end

  context 'starts the redis service' do
    # We use grep and commands here, since serverspec only checks systemd on fedora 20
    # instead of also being able to check sysv style init systems.
    describe command('ps aux | grep -v grep | grep \'redis-server\' | grep \'*:6379\'') do
      its(:exit_status) { should eq(0) }
    end
  end

  it 'is listening on port 6379' do
    expect(port 6379).to be_listening
  end

end
