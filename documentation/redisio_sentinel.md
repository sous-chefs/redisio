# redisio_sentinel

Compatibility wrapper that expands the legacy `sentinel_defaults` plus `sentinels` payload into one `redisio_sentinel_instance` resource per instance.

## Actions

- `:create`: Creates all sentinel instances from the payload
- `:delete`: Removes all sentinel instances from the payload

## Properties

- `version` (`String`, default: `nil`): Redis version override
- `base_piddir` (`String`, default: `/var/run/redis`): Base pid directory
- `user` (`String`, default: `redis`): Default user fallback
- `group` (`String`, default: `redis`): Default group fallback
- `sentinel_defaults` (`Hash`, default: `{}`): Shared settings merged into every sentinel definition
- `sentinels` (`Array`, default: `nil`): Sentinel definitions; `nil` creates the historic default `mycluster` definition
- `package_install` (`Boolean`, default: `false`): Package install compatibility hint
- `package_name`, `install_dir`, `bin_path`: Compatibility hints for downstream sentinel resources

## Examples

```ruby
redisio_sentinel 'default' do
  package_install true
  sentinels [
    {
      'name' => 'cluster',
      'masters' => [
        { 'master_name' => 'master6379', 'master_ip' => '127.0.0.1', 'master_port' => 6379 },
      ],
    },
  ]
end
```
