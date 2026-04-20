# frozen_string_literal: true

redisio_install 'default' do
  package_install true
end

redisio_server '6379' do
  package_install true
end

redisio_server 'savetest' do
  package_install true
  port 16_379
  permissions '0640'
  save ['3600 1', '300 100', '60 10000']
  logfile '/var/log/redis/redis-16379.log'
end
