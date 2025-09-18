directory '/etc/redis/ssl' do
  owner 'redis'
  group 'redis'
  mode '0755'
  action :create
end

openssl_x509_certificate '/etc/redis/ssl/redis-ca.crt' do
  common_name 'redis-ca'
  expire 365
  extensions(
    'keyUsage' => {
      'values' => %w(
        keyCertSign
        keyEncipherment
        digitalSignature
        cRLSign),
      'critical' => true,
    }
  )
  owner 'redis'
  group 'redis'
  action :create
end

openssl_x509_certificate '/etc/redis/ssl/redis.crt' do
  common_name 'redis'
  ca_key_file '/etc/redis/ssl/redis-ca.key'
  ca_cert_file '/etc/redis/ssl/redis-ca.crt'
  expire 365
  extensions(
    'keyUsage' => {
      'values' => %w(
        keyEncipherment
        digitalSignature),
      'critical' => true,
    },
    'extendedKeyUsage' => {
      'values' => %w(
        serverAuth
        clientAuth),
      'critical' => false,
    }
  )
  owner 'redis'
  group 'redis'
  action :create
end
