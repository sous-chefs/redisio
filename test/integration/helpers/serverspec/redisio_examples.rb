shared_examples_for 'redis on port' do |redis_port, args|
  it 'enables the redis service' do
    service_name = if os[:family] == 'redhat' and os[:release][0] == '7'
                     "redis@#{redis_port}"
                   else
                     "redis#{redis_port}"
                   end
    expect(service service_name).to be_enabled
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
