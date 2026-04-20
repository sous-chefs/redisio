# Redisio Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/redisio.svg)](https://supermarket.chef.io/cookbooks/redisio)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

`redisio` is a resource-first Sous Chefs cookbook for installing Redis and managing Redis server and Sentinel instances with systemd.

## Supported Platforms

- Amazon Linux 2023
- Debian 12 and 13
- Rocky Linux 9
- Ubuntu 22.04 and 24.04

See [LIMITATIONS.md](LIMITATIONS.md) for package and source-build constraints.

## Resources

### Preferred resources

- `redisio_install`
- `redisio_server`
- `redisio_sentinel_instance`

### Compatibility wrappers

- `redisio_configure`
- `redisio_sentinel`

The compatibility wrappers preserve the old aggregate `servers` and `sentinels` payload shapes while delegating to the new per-instance resources.

## Basic Usage

### Install Redis from packages and start one instance

```ruby
redisio_install 'default' do
  package_install true
end

redisio_server '6379' do
  package_install true
end
```

### Create a named secondary instance

```ruby
redisio_server 'savetest' do
  package_install true
  port 16_379
  permissions '0640'
  save ['3600 1', '300 100', '60 10000']
  logfile '/var/log/redis/redis-16379.log'
end
```

### Create a Sentinel instance

```ruby
redisio_sentinel_instance 'cluster' do
  package_install true
  masters [
    {
      master_name: 'master6379',
      master_ip: '127.0.0.1',
      master_port: 6379,
    },
  ]
end
```

### Use the compatibility wrapper

```ruby
redisio_configure 'default' do
  package_install true
  servers [
    { 'port' => 6379 },
    { 'name' => 'savetest', 'port' => 16_379, 'permissions' => '0640' },
  ]
end
```

## Testing

Run lint and unit tests with:

```bash
cookstyle
chef exec rspec --format documentation
```

Run the default integration suite with:

```bash
KITCHEN_LOCAL_YAML=kitchen.dokken.yml kitchen test default-ubuntu-2404 --destroy=always
```

Additional public API details live in `documentation/*.md`.
