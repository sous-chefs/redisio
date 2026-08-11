# Installation limitations

## Package availability

Ubuntu 22.04 and 24.04 and Debian 12 and 13 are supported by the official Redis APT repository. Redis also publishes RPM repository instructions for Rocky Linux 9. The cookbook does not configure these repositories; package resources use the repositories already configured on the node.

Amazon Linux 2023 provides `redis6` through its distribution package set rather than the package names used by Debian, Ubuntu, and Rocky Linux. Set `package_name` explicitly when the platform default does not match the configured repository.

Package names and versions can differ by architecture. The cookbook's continuous integration matrix validates supported Linux platforms but does not test every architecture and repository combination.

## Source installation

Source installation remains available as a compatibility path and requires the following build dependencies:

| Platform family | Packages |
| --- | --- |
| Debian and Ubuntu | `tar`, `gcc`, `g++`, `make`, `libc6-dev`, `libssl-dev` |
| Rocky and Amazon | `tar`, `gcc`, `gcc-c++`, `make`, `glibc-devel`, `openssl-devel` |

Redis source builds require a C compiler and libc. TLS builds additionally require OpenSSL development libraries.
