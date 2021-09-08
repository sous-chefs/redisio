# debian 6.0.x fails the build_essential recipe without an apt-get update prior to run
if platform?('debian', 'ubuntu')
  execute 'apt-get-update-periodic' do
    command 'apt-get update'
    ignore_failure true
    only_if do
      !File.exist?('/var/lib/apt/periodic/update-success-stamp') ||
        File.mtime('/var/lib/apt/periodic/update-success-stamp') < Time.now - 86400
    end
  end
end

unless node['redisio']['package_install']
  include_recipe 'redisio::_install_prereqs'
  build_essential 'install build deps'
end

unless node['redisio']['bypass_setup']
  include_recipe 'redisio::install'
  include_recipe 'redisio::disable_os_default'
  include_recipe 'redisio::configure'
end
