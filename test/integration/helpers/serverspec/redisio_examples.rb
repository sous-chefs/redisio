shared_examples_for 'redis on port' do |redis_port, args|
  it 'enables the redis service' do
    expect(service "redis#{redis_port}").to be_enabled
  end

  context 'starts the redis service' do
    # We use grep and commands here, since serverspec only checks systemd on fedora 20
    # instead of also being able to check sysv style init systems.
    describe command("ps aux | grep -v grep | grep 'redis-server' | grep '*:#{redis_port}'") do
      its(:exit_status) { should eq(0) }
    end
  end

  it "is listening on port #{redis_port}" do
    expect(port redis_port).to be_listening
  end
end
