require 'spec_helper'

describe 'Redis' do

  it 'enables the redis service' do
    expect(service 'redis6379').to be_enabled
  end

  it 'starts the redis service' do
    # be_running uses ps aux, the service runs as redis-server *:6379 not as the service name redis6379
    # Ensure a redis process is running on port 6379. .* regex to match everything between redis and port
    expect(service 'redis6379').to be_running
  end

  it 'is listening on port 6379' do
    expect(port 6379).to be_listening
  end

end
