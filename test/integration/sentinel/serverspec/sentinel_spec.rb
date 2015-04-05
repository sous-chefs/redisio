require 'spec_helper'

describe 'Redis-Sentinel' do

  it 'enables the redis-sentinel service' do
    expect(service 'redis_sentinel_mycluster').to be_enabled
  end

  context 'starts the redis-setinel service' do
    describe command('ps aux | grep -v grep | grep \'redis-server\' | grep \'*:26379\'') do
      its(:exit_status) { should eq(0) }
    end
  end

  it 'is listening on port 26379' do
    expect(port 26379).to be_listening
  end

end
