# disable the default OS redis init script
service_name = case node['platform_family']
               when 'debian'
                 'redis-server'
               when 'rhel', 'fedora'
                 'redis'
               end

service service_name do
  action [:stop, :disable]
  only_if { service_name }
end
