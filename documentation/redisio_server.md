# redisio_server

Manages a single Redis server instance, including config, systemd unit, runtime directories, and service state.

## Actions

- `:create`: Creates the instance config and starts the service
- `:delete`: Stops the service and removes instance-specific artifacts

## Properties

- `instance_name` (`String`, default: name): Instance identifier used in service/config naming
- `package_install` (`Boolean`, default: `false`): Whether package install conventions should be used for binaries
- `install_dir` (`String`, default: `nil`): Alternate source install prefix
- `bin_path` (`String`, default: derived): Binary directory override
- `port` (`String`, `Integer`, default: `6379`): Listening port
- `name_override` (`String`, default: `nil`): Alternate config/service name when needed for compatibility
- `configdir` (`String`, default: `/etc/redis`): Config directory
- `datadir` (`String`, default: `/var/lib/redis`): Data directory
- `user` (`String`, default: `redis`): Service user
- `group` (`String`, default: `redis`): Service group
- `permissions` (`String`, default: `0644`): Mode for the rendered config file
- `save` (`Array`, `String`, default: `nil`): Save directives for the instance
- `logfile` (`String`, default: `nil`): Optional log file path
- `maxclients` (`Integer`, default: `10000`): Max connected clients
- `maxmemory` (`String`, default: `nil`): Max memory or percentage string
- `requirepass` (`String`, default: `nil`): Optional auth password
- `masterauth` (`String`, default: `nil`): Optional replication auth password
- `data_bag_name`, `data_bag_item`, `data_bag_key` (`String`): Optional data bag lookup for passwords
- `breadcrumb` (`Boolean`, default: `true`): Write-once config guard

## Examples

### Create the primary instance

```ruby
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
