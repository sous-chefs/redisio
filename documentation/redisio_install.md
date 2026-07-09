# redisio_install

Installs or removes Redis or Valkey either from distro packages or from source.

## Actions

- `:create`: Installs Redis and disables the packaged default service
- `:delete`: Removes Redis package artifacts or source-installed binaries

## Properties

- `package_install` (`Boolean`, default: `false`): Install from OS packages instead of source
- `server_implementation` (`String`, default: `redis`): Select `redis` or `valkey`
- `package_name` (`String`, default: platform specific): Package name override
- `version` (`String`, default: source installs use `3.2.11`): Redis version to install
- `download_url` (`String`, default: derived): Tarball URL for source installs
- `download_dir` (`String`, default: Chef file cache path): Download/extract directory
- `artifact_type` (`String`, default: `tar.gz`): Source archive suffix
- `base_name` (`String`, default: `redis-`): Source archive prefix
- `safe_install` (`Boolean`, default: `true`): Skip source install when Redis is already present
- `install_dir` (`String`, default: `nil`): Alternate install prefix for source builds

## Examples

### Install from the OS package manager

```ruby
redisio_install 'default' do
  package_install true
end
```

### Install Valkey from packages

```ruby
redisio_install 'default' do
  package_install true
  server_implementation 'valkey'
end
```

### Install a specific source release

```ruby
redisio_install 'default' do
  version '7.4.8'
end
```

Valkey support in this resource is currently package-only. Source installs still target Redis.
