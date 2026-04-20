# Limitations

## Package Availability

### APT (Debian/Ubuntu)

- Ubuntu 22.04 and 24.04 are explicitly tested by Redis upstream and supported by the official APT repository at `https://packages.redis.io/deb`.
- Debian 12 and 13 are explicitly tested by Redis upstream and supported by the official APT repository at `https://packages.redis.io/deb`.
- The official APT repository provides `redis`, `redis-server`, `redis-sentinel`, and `redis-tools`, with architecture-specific packages such as `amd64`.

### RPM (RHEL family)

- Redis upstream publishes official RPM repository instructions for Rocky Linux 8 and 9 and AlmaLinux 8 and 9.
- This cookbook CI targets Rocky Linux 9 only.
- Amazon Linux 2023 does not have an official Redis upstream repository in the Redis installation docs. For Amazon Linux 2023, package availability comes from the distro package set or from source builds.

## Architecture Limitations

- Redis upstream documents tested Linux platforms but does not promise identical package availability across every architecture in the install guide.
- The official APT examples show architecture-specific package indexes such as `amd64`.
- The cookbook CI validates Linux platform support, not every architecture permutation.

## Source/Compiled Installation

### Build Dependencies

| Platform Family | Packages                                                        |
|-----------------|-----------------------------------------------------------------|
| Debian/Ubuntu   | `tar`, `gcc`, `g++`, `make`, `libc6-dev`, `libssl-dev`          |
| Rocky/Amazon    | `tar`, `gcc`, `gcc-c++`, `make`, `glibc-devel`, `openssl-devel` |

- Redis upstream documents source builds for Linux and macOS using a C compiler and `libc`, with OpenSSL development libraries required for TLS builds.
- This cookbook preserves source installs primarily as a compatibility path where package installs are not suitable.

## Known Issues

- Amazon Linux 2023 ships `redis6` in the distro package set rather than matching the package names used by Debian, Ubuntu, and Rocky Linux.
- Amazon Linux 2023 package support for Redis 6 is time-bounded by Amazon Linux package support, so current package installs there lag the upstream Redis release stream.
- Rocky Linux 8 remains in security support but is no longer in active support; this cookbook narrows CI to Rocky Linux 9.
