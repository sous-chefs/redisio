# redisio_configure

Compatibility wrapper that expands the legacy `default_settings` plus `servers` payload into one `redisio_server` resource per instance.

## Actions

- `:create`: Creates all server instances from the payload
- `:delete`: Removes all server instances from the payload

## Properties

- `version` (`String`, default: `nil`): Redis or Valkey version override
- `server_implementation` (`String`, default: `redis`): Select `redis` or `valkey`
- `base_piddir` (`String`, default: implementation specific): Base pid directory
- `user` (`String`, default: implementation specific): Default user fallback
- `group` (`String`, default: implementation specific): Default group fallback
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
