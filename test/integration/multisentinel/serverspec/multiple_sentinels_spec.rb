require 'spec_helper'

prefix = os[:family] == 'freebsd' ? '/usr/local' : ''

describe 'Redis-Sentinel' do
  it_behaves_like 'sentinel on port', 26379, 'cluster'
end

describe file("#{prefix}/etc/redis/sentinel_cluster.conf") do
  [
    /sentinel monitor master6379 127.0.0.1 6379 2/,
    /sentinel down-after-milliseconds master6379 30000/,
    /sentinel parallel-syncs master6379 1/,
    /sentinel failover-timeout master6379 900000/,
    /sentinel monitor master6380 127.0.0.1 6380 2/,
    /sentinel down-after-milliseconds master6380 30000/,
    /sentinel parallel-syncs master6380 1/,
    /sentinel failover-timeout master6380 900000/,
  ].each do |pattern|
    its(:content) { should match(pattern) }
  end
end

unless (os[:family] == 'redhat' && os[:release][0] == '7') ||
       os[:family] == 'freebsd' ||
       (os[:family] == 'ubuntu' && os[:release].to_f >= 16.04) ||
       (os[:family] == 'debian' && os[:release].to_f >= 8.0) ||
       os[:family] == 'fedora'
  describe file('/etc/init.d/redis_sentinel_cluster') do
    [
      /SENTINELNAME=sentinel_cluster/,
      %r{EXEC="(su -s /bin/sh)|(runuser redis) -c \\?["']/usr/local/bin/redis-server /etc/redis/\$\{SENTINELNAME\}.conf --sentinel\\?["']( redis)?"},
      %r{PIDFILE=/var/run/redis/sentinel_cluster/\$\{SENTINELNAME\}.pid},
      %r{mkdir -p /var/run/redis/sentinel_cluster},
      %r{chown redis  /var/run/redis/sentinel_cluster},
    ].each do |pattern|
      its(:content) { should match(pattern) }
    end
  end
end

describe command('/usr/local/bin/redis-cli --raw -p 26379 SENTINEL MASTER master6379') do
  [
    /name/,
    /master6379/,
    /ip/,
    /127.0.0.1/,
    /port/,
    /6379/,
    /flags/,
    /master/,
    /last-ping-sent/,
    /last-ok-ping-reply/,
    /last-ping-reply/,
    /down-after-milliseconds/,
    /30000/,
    /role-reported/,
    /master/,
    /config-epoch/,
    /0/,
    /num-slaves/,
    /0/,
    /num-other-sentinels/,
    /0/,
    /quorum/,
    /2/,
    /failover-timeout/,
    /900000/,
    /parallel-syncs/,
    /1/,
  ].each do |pattern|
    its(:stdout) { should match(pattern) }
  end
end

describe command('/usr/local/bin/redis-cli --raw -p 26379 SENTINEL MASTER master6380') do
  [
    /name/,
    /master6380/,
    /ip/,
    /127.0.0.1/,
    /port/,
    /6380/,
    /flags/,
    /master/,
    /last-ping-sent/,
    /last-ok-ping-reply/,
    /last-ping-reply/,
    /down-after-milliseconds/,
    /30000/,
    /role-reported/,
    /master/,
    /config-epoch/,
    /0/,
    /num-slaves/,
    /0/,
    /num-other-sentinels/,
    /0/,
    /quorum/,
    /2/,
    /failover-timeout/,
    /900000/,
    /parallel-syncs/,
    /1/,
  ].each do |pattern|
    its(:stdout) { should match(pattern) }
  end
end
