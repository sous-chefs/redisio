# Upgrading to version 8

Version 8 replaces the recipe- and attribute-driven interface from version 7 with Chef custom resources. It also narrows the supported platform and service-manager matrix. Version 7.2.5 was never published; upgrade from the last published version, 7.2.4, directly to version 8.

## Before upgrading

- Pin version 7.2.4 until the consuming wrapper cookbook has been migrated.
- Back up Redis data and the generated Redis and Sentinel configuration files.
- Test the migration with the same Redis package or source version used in production.
- Keep instance names, ports, config directories, and data directories unchanged on the first version 8 converge.

## Replace recipes and node attributes

Version 8 removes all `redisio` recipes and does not read `node['redisio']` attributes. Declare resources in a wrapper cookbook instead. The resources create, enable, and start their systemd services, so the old enable recipes have no direct replacement.

Replace a package-backed server such as:

```ruby
node.default['redisio']['package_install'] = true
node.default['redisio']['servers'] = [{ 'port' => 6379 }]

include_recipe 'redisio'
include_recipe 'redisio::enable'
```

with:

```ruby
redisio_install 'default' do
  package_install true
end

redisio_server '6379' do
  package_install true
  port 6379
end
```

The `redisio_configure` resource accepts the old `default_settings` and `servers` payload shapes when a gradual migration is preferable:

```ruby
redisio_install 'default' do
  package_install true
end

redisio_configure 'default' do
  package_install true
  default_settings(
    'datadir' => '/var/lib/redis',
    'permissions' => '0640'
  )
  servers [
    { 'port' => 6379 },
    { 'name' => 'cache', 'port' => 6380 },
  ]
end
```

Likewise, replace `redisio::sentinel` and `redisio::sentinel_enable` with `redisio_sentinel_instance`, or pass the old `sentinel_defaults` and `sentinels` payloads to the `redisio_sentinel` compatibility resource.

The removed `redisio::redis_gem` recipe has no resource wrapper. Manage the required Ruby gem explicitly with `chef_gem` or `gem_package` in the consuming cookbook.

## Update explicit resource actions

The version 7 `redisio_install`, `redisio_configure`, and `redisio_sentinel` resources exposed `:run` as their only action. Version 8 does not support `:run`; replace every explicit `action :run` with `action :create`. Omitting the action also selects `:create` by default.

For example, replace:

```ruby
redisio_install 'redis-installation' do
  version '7.4.8'
  action :run
end
```

with:

```ruby
redisio_install 'redis-installation' do
  version '7.4.8'
  action :create
end
```

Version 8 resource actions are:

- `redisio_install`: `:create` and `:delete`
- `redisio_server`: `:create` and `:delete`
- `redisio_sentinel_instance`: `:create` and `:delete`
- `redisio_configure`: `:create` only
- `redisio_sentinel`: `:create` only

Use `:delete` deliberately. `redisio_install` removes the managed package or source-installed binaries. `redisio_server` stops and disables the service and removes its instance files, including the configured data directory. `redisio_sentinel_instance` stops and disables the service and removes its instance configuration and runtime files. Back up Redis data before deleting an instance. The compatibility wrapper resources do not provide a bulk `:delete` action; use the per-instance resources for teardown.

## Account for platform changes

Version 8 supports Amazon Linux 2023, Debian 12 and 13, Rocky Linux 9, and Ubuntu 22.04 and 24.04. Support for CentOS, Fedora, Red Hat Enterprise Linux, Scientific Linux, SUSE, FreeBSD, and older releases of the retained platforms has been removed.

Only systemd services are supported. The init.d, Upstart, and rc.d implementations from version 7 have been removed. Server services are named `redis@INSTANCE`; Sentinel services are named `redis-sentinel@INSTANCE`.

## Choose the installation source explicitly

`redisio_install` builds Redis from source by default. Set `package_install true` on the install, server, and Sentinel resources when using packages. The cookbook installs from configured operating-system repositories; it does not add the upstream Redis APT or RPM repository. Declare any additional repository in the wrapper cookbook before `redisio_install`.

See the [resource documentation](documentation/) for all properties.
