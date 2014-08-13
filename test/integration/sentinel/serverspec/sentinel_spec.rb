require 'spec_helper'

describe 'Redis-Sentinel' do

  it 'enables the redis-sentinel service' do
    expect(service 'redis_sentinel_mycluster').to be_enabled
  end

  it 'starts the redis-setinel service' do
    expect(service 'redis_sentinel_mycluster').to be_running
  end

  it 'is listening on port 26379' do
    expect(port 26379).to be_listening
  end

end
