# frozen_string_literal: true

require 'shellwords'

module RedisioCookbook
  module Helpers
    def valkey_implementation?(server_implementation)
      server_implementation.to_s == 'valkey'
    end

    def package_only_implementation?(server_implementation)
      valkey_implementation?(server_implementation)
    end

    def validate_server_implementation!(package_install:, server_implementation:)
      return unless package_only_implementation?(server_implementation) && !package_install

      raise 'Valkey support currently requires package_install true'
    end

    def platform_package_names(server_implementation:, include_sentinel: false)
      if valkey_implementation?(server_implementation)
        if platform_family?('debian')
          packages = %w(valkey-server valkey-tools)
          packages << 'valkey-sentinel' if include_sentinel
          return packages
        end

        return ['valkey']
      end

      return ['redis6'] if platform_family?('amazon')
      return ['redis-server'] if platform_family?('debian')

      ['redis']
    end

    def platform_package_name(server_implementation:)
      platform_package_names(server_implementation: server_implementation).first
    end

    def platform_default_home(server_implementation:)
      return '/var/lib/valkey' if valkey_implementation?(server_implementation)

      '/var/lib/redis'
    end

    def platform_default_shell
      return '/bin/false' if platform_family?('debian')

      '/bin/sh'
    end

    def platform_default_group(server_implementation:)
      return 'valkey' if valkey_implementation?(server_implementation)

      'redis'
    end

    def platform_default_config_dir(server_implementation:)
      return '/etc/valkey' if valkey_implementation?(server_implementation)

      '/etc/redis'
    end

    def platform_default_service_name(server_implementation:)
      return 'valkey' if valkey_implementation?(server_implementation)
      return 'redis6' if platform_family?('amazon')
      return 'redis-server' if platform_family?('debian')

      'redis'
    end

    def package_default_service_names(server_implementation:)
      if valkey_implementation?(server_implementation)
        return %w(valkey valkey-sentinel)
      end

      [platform_default_service_name(server_implementation: server_implementation)]
    end

    def platform_default_bin_path(package_install:, install_dir:)
      return ::File.join(install_dir, 'bin') if install_dir
      return '/usr/bin' if package_install

      '/usr/local/bin'
    end

    def platform_default_base_piddir(server_implementation:)
      return '/var/run/valkey' if valkey_implementation?(server_implementation)

      '/var/run/redis'
    end

    def source_build_packages
      return %w(tar gcc g++ make libc6-dev libssl-dev) if platform_family?('debian')

      %w(tar gcc gcc-c++ make glibc-devel openssl-devel)
    end

    def redis_service_name(instance_name, server_implementation:)
      return "valkey@#{instance_name}" if valkey_implementation?(server_implementation)

      "redis@#{instance_name}"
    end

    def sentinel_service_name(instance_name, server_implementation:)
      return "valkey-sentinel@#{instance_name}" if valkey_implementation?(server_implementation)

      "redis-sentinel@#{instance_name}"
    end

    def sentinel_config_name(instance_name)
      "sentinel_#{instance_name}"
    end

    def redis_version_to_hash(version_string)
      version_array = version_string.to_s.split('.')
      version_array[2] = version_array[2].to_s.split('-')
      version_array.flatten!

      {
        major: version_array.first.to_s.include?(':') ? version_array.first.split(':')[1] : version_array.first,
        minor: version_array[1],
        tiny: version_array[2],
        rc: version_array[3],
      }
    end

    def redis_server_binary_name(package_install:, package_name:, server_implementation:)
      return 'valkey-server' if valkey_implementation?(server_implementation)
      return 'redis6-server' if package_install && package_name == 'redis6'

      'redis-server'
    end

    def redis_cli_binary_name(package_install:, package_name:, server_implementation:)
      return 'valkey-cli' if valkey_implementation?(server_implementation)
      return 'redis6-cli' if package_install && package_name == 'redis6'

      'redis-cli'
    end

    def redis_server_binary(bin_path, options = nil, package_install: nil, package_name: nil, server_implementation: nil)
      if options.is_a?(Hash)
        package_install = options.fetch(:package_install, package_install)
        package_name = options.fetch(:package_name, package_name)
        server_implementation = options.fetch(:server_implementation, server_implementation)
      end

      ::File.join(
        bin_path,
        redis_server_binary_name(
          package_install: package_install,
          package_name: package_name,
          server_implementation: server_implementation
        )
      )
    end

    def redis_cli_binary(bin_path, options = nil, package_install: nil, package_name: nil, server_implementation: nil)
      if options.is_a?(Hash)
        package_install = options.fetch(:package_install, package_install)
        package_name = options.fetch(:package_name, package_name)
        server_implementation = options.fetch(:server_implementation, server_implementation)
      end

      ::File.join(
        bin_path,
        redis_cli_binary_name(
          package_install: package_install,
          package_name: package_name,
          server_implementation: server_implementation
        )
      )
    end

    def installed_redis_version(bin_path, package_install:, package_name:, server_implementation:)
      redis_server = redis_server_binary(
        bin_path,
        package_install: package_install,
        package_name: package_name,
        server_implementation: server_implementation
      )
      return unless ::File.exist?(redis_server)

      command = shell_out!("#{Shellwords.escape(redis_server)} -v", timeout: 30)
      command.stdout[/version (\d+\.\d+\.\d+)/, 1] || command.stdout[/v=(\d+\.\d+\.\d+)/, 1]
    end

    def normalize_hash(value)
      return {} if value.nil?
      return value.to_hash if value.respond_to?(:to_hash)

      value
    end

    def normalize_array(value)
      return [] if value.nil?

      Array(value)
    end

    def deep_stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, inner), result|
          result[key.to_s] = deep_stringify_keys(inner)
        end
      when Array
        value.map { |inner| deep_stringify_keys(inner) }
      else
        value
      end
    end

    def command_exists?(command)
      shell_out("command -v #{Shellwords.escape(command)}").exitstatus.zero?
    end
  end
end
