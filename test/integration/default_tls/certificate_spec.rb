describe x509_certificate('/etc/redis/ssl/redis.crt') do
  it { should be_certificate }
  its('key_length') { should be 2048 }
  its('validity_in_days') { should be > 30 }
  its('subject.CN') { should match 'redis' }
  its('issuer.CN') { should match /redis-ca/ }
end

describe x509_certificate('/etc/redis/ssl/redis-ca.crt') do
  it { should be_certificate }
  its('key_length') { should be 2048 }
  its('validity_in_days') { should be > 30 }
  its('subject.CN') { should match 'redis-ca' }
  its('issuer.CN') { should match /redis-ca/ }
end
