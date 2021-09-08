gem_package node['redisio']['gem']['name'] do
  version node['redisio']['gem']['version'] unless node['redisio']['gem']['version'].nil?
  action :install
end
