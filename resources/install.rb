# frozen_string_literal: true

provides :redisio_install
unified_mode true

property :package_install, [true, false], default: false
property :package_name, [String, NilClass]
property :version, [String, NilClass]
property :download_url, [String, NilClass]
property :download_dir, String, default: lazy { Chef::Config[:file_cache_path] }
property :artifact_type, String, default: 'tar.gz'
property :base_name, String, default: 'redis-'
property :safe_install, [true, false], default: true
property :install_dir, [String, NilClass]

action_class do
  include RedisioCookbook::Helpers

  def resolved_package_name
    new_resource.package_name || platform_package_name
  end

  def resolved_version
    return new_resource.version if new_resource.version
    return if new_resource.package_install

    '3.2.11'
  end

  def resolved_download_url
    return new_resource.download_url if new_resource.download_url

    version = resolved_version || 'redis-stable'
    file_name = version == 'redis-stable' ? version : "#{new_resource.base_name}#{version}"
    "https://download.redis.io/#{file_name}.#{new_resource.artifact_type}"
  end

  def resolved_bin_path
    platform_default_bin_path(package_install: new_resource.package_install, install_dir: new_resource.install_dir)
  end

  def resolved_server_binary
    redis_server_binary(resolved_bin_path, package_install: new_resource.package_install, package_name: resolved_package_name)
  end

  def tarball_name
    return 'redis-stable.tar.gz' if resolved_download_url.end_with?('redis-stable.tar.gz')

    "#{new_resource.base_name}#{resolved_version}.#{new_resource.artifact_type}"
  end

  def source_directory
    return 'redis-stable' if tarball_name.start_with?('redis-stable')

    "#{new_resource.base_name}#{new_resource.version}"
  end

  def package_service_name
    platform_default_service_name
  end
end

action :create do
  if new_resource.package_install
    if platform_family?('debian')
      apt_update 'redisio-package-cache'
    end

    package resolved_package_name do
      version resolved_version unless resolved_version.nil?
    end

    service package_service_name do
      action %i(stop disable)
    end
  else
    source_build_packages.each do |build_package|
      package build_package
    end

    current_version = installed_redis_version(resolved_bin_path, package_install: new_resource.package_install, package_name: resolved_package_name)
    converge_if_changed :version do
      if current_version == resolved_version || (current_version && new_resource.safe_install)
        Chef::Log.info("Skipping Redis source install because #{current_version} is already present")
      else
        remote_file "#{new_resource.download_dir}/#{tarball_name}" do
          source resolved_download_url
        end

        directory "#{new_resource.download_dir}/#{source_directory}" do
          recursive true
        end

        execute "extract-#{source_directory}" do
          cwd new_resource.download_dir
          command "tar zxf #{Shellwords.escape(tarball_name)} --strip-components=1 -C #{Shellwords.escape(source_directory)} --no-same-owner"
          creates "#{new_resource.download_dir}/#{source_directory}/src/redis-server"
        end

        execute "build-#{source_directory}" do
          cwd "#{new_resource.download_dir}/#{source_directory}"
          command 'make clean && make'
        end

        execute "install-#{source_directory}" do
          cwd "#{new_resource.download_dir}/#{source_directory}"
          command new_resource.install_dir ? "make PREFIX=#{Shellwords.escape(new_resource.install_dir)} install" : 'make install'
        end
      end
    end
  end
end

action :delete do
  if new_resource.package_install
    service package_service_name do
      action %i(stop disable)
    end

    package resolved_package_name do
      action :remove
    end
  else
    binaries = %w(redis-benchmark redis-check-aof redis-check-rdb redis-sentinel)
    binaries.unshift(redis_server_binary_name(package_install: new_resource.package_install, package_name: resolved_package_name))
    binaries.unshift(redis_cli_binary_name(package_install: new_resource.package_install, package_name: resolved_package_name))

    binaries.each do |binary|
      file ::File.join(resolved_bin_path, binary) do
        action :delete
      end
    end
  end
end
