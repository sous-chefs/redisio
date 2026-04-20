# frozen_string_literal: true

redisio_install 'default' do
  package_install true
end

redisio_server '6379' do
  package_install true
end

redisio_server '6380' do
  package_install true
  port 6380
end

redisio_sentinel_instance 'cluster' do
  package_install true
  sentinel_bind '0.0.0.0'
  masters [
    {
      master_name: 'master6379',
      master_ip: '127.0.0.1',
      master_port: 6379,
    },
    {
      master_name: 'master6380',
      master_ip: '127.0.0.1',
      master_port: 6380,
    },
  ]
end
