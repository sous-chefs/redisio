apt_update

unless node['redisio']['package_install']
  include_recipe 'redisio::_install_prereqs'
  build_essential 'install build deps'
end

unless node['redisio']['bypass_setup']
  include_recipe 'redisio::install'
  include_recipe 'redisio::disable_os_default'
  include_recipe 'redisio::configure'
end
