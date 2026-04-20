# redisio_configure

Compatibility wrapper that expands the legacy `default_settings` plus `servers` payload into one `redisio_server` resource per instance.

## Actions

- `:create`: Creates all server instances from the payload
- `:delete`: Removes all server instances from the payload

## Properties

- `version` (`String`, default: `nil`): Redis version override
- `base_piddir` (`String`, default: `/var/run/redis`): Base pid directory
- `user` (`String`, default: `redis`): Default user fallback
- `group` (`String`, default: `redis`): Default group fallback
- `default_settings` (`Hash`, default: `{}`): Shared settings merged into every server definition
- `servers` (`Array`, default: `nil`): Server definitions; `nil` creates one default `6379` instance
- `package_install` (`Boolean`, default: `false`): Package install compatibility hint
- `package_name`, `install_dir`, `bin_path`: Compatibility hints for downstream server resources

## Examples

```ruby
redisio_configure 'default' do
  package_install true
  servers [
    { 'port' => 6379 },
    { 'name' => 'savetest', 'port' => 16_379, 'permissions' => '0640' },
  ]
end
```
