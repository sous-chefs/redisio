# frozen_string_literal: true

def amazon_linux?
  os.family == 'amazon' || os.name == 'amazon'
end

def redis_package_name
  return 'redis-server' if os.family == 'debian'
  return 'redis6' if amazon_linux?

  'redis'
end

def redis_service_name(instance_name)
  "redis@#{instance_name}"
end

def redis_sentinel_service_name(instance_name)
  "redis-sentinel@#{instance_name}"
end

def redis_cli_binary
  return '/usr/bin/redis6-cli' if amazon_linux?

  '/usr/bin/redis-cli'
end
