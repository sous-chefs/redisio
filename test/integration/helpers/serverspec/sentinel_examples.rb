shared_examples_for 'sentinel on port' do |redis_port, args|
  it 'enables the redis-sentinel service' do
    expect(service 'redis_sentinel_mycluster').to be_enabled
  end

  context 'starts the redis-setinel service' do
    describe command("ps aux | grep -v grep | grep 'redis-server' | grep '*:#{redis_port}'") do
      its(:exit_status) { should eq(0) }
    end
  end

  it "is listening on port #{redis_port}" do
    expect(port redis_port).to be_listening
  end
end
