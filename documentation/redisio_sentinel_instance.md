# redisio_sentinel_instance

Manages a single Redis or Valkey Sentinel instance, including config, systemd unit, and service state.

## Actions

- `:create`: Creates the Sentinel config and starts the service
- `:delete`: Stops the service and removes instance-specific artifacts

## Properties

- `instance_name` (`String`, default: name): Sentinel instance identifier
- `package_install` (`Boolean`, default: `false`): Whether package install conventions should be used for binaries
- `server_implementation` (`String`, default: `redis`): Select `redis` or `valkey`
- `install_dir` (`String`, default: `nil`): Alternate source install prefix
- `bin_path` (`String`, default: derived): Binary directory override
- `sentinel_bind` (`String`, default: `nil`): Optional bind address
- `sentinel_port` (`String`, `Integer`, default: `26379`): Sentinel listen port
- `masters` (`Array`, default: `[]`): Monitored master definitions
- `master_name`, `master_ip`, `master_port` (`String`): Deprecated flat single-master compatibility shape
- `quorum_count` (`Integer`, default: `2`): Required sentinel quorum
- `down_after_milliseconds` (`Integer`, default: `30000`): Failure detection timeout
- `parallel_syncs` (`Integer`, default: `1`): Replica resync count
- `failover_timeout` (`Integer`, default: `900000`): Failover timeout
- `announce_ip`, `announce_port` (`String`, `Integer`): Optional announce values
- `notification_script`, `client_reconfig_script` (`String`): Optional callback scripts

## Examples

### Create a sentinel for a single master

```ruby
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
```

### Create a Valkey sentinel

```ruby
redisio_sentinel_instance 'mycluster' do
  package_install true
  server_implementation 'valkey'
  masters [
    {
      master_name: 'mycluster_master',
      master_ip: '127.0.0.1',
      master_port: 6379,
    },
  ]
end
```
