# frozen_string_literal: true

redisio_install 'default' do
  package_install true
end

redisio_server '6379' do
  package_install true
end

redisio_sentinel_instance 'mycluster' do
  package_install true
  masters [
    {
      master_name: 'mycluster_master',
      master_ip: '127.0.0.1',
      master_port: 6379,
    },
  ]
end
