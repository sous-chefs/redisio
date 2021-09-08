if node['redisio']['package_install']
  package 'redisio_package_name' do
    package_name node['redisio']['package_name']
    version node['redisio']['version'] if node['redisio']['version']
    action :install
  end
else
  include_recipe 'redisio::_install_prereqs'
  build_essential 'install build deps'

  redis = node['redisio']
  location = "#{redis['mirror']}/#{redis['base_name']}#{redis['version']}.#{redis['artifact_type']}"

  redisio_install 'redis-installation' do
    version redis['version'] if redis['version']
    download_url location
    safe_install redis['safe_install']
    install_dir redis['install_dir'] if redis['install_dir']
  end
end

include_recipe 'ulimit::default'
