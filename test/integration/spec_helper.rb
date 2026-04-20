# frozen_string_literal: true

def redis_package_name
  return 'redis-server' if os.family == 'debian'
  return 'redis6' if os.family == 'amazon'

  'redis'
end

def redis_service_name(instance_name)
  "redis@#{instance_name}"
end

def redis_sentinel_service_name(instance_name)
  "redis-sentinel@#{instance_name}"
end

def redis_cli_binary
  return '/usr/bin/redis6-cli' if os.family == 'amazon'

  '/usr/bin/redis-cli'
end
