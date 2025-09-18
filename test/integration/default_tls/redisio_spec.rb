describe service('redis@6379-tls') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe port(6379) do
  it { should be_listening }
end

describe command('redis-cli -h localhost -p 6379 --tls --cert /etc/redis/ssl/redis.crt --key /etc/redis/ssl/redis.key --cacert /etc/redis/ssl/redis-ca.crt ping') do
  its(:stdout) { should match 'PONG' }
  its('exit_status') { should eq 0 }
end
