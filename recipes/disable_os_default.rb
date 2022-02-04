# disable the default OS redis init script
service_name = case node['platform']
               when 'debian', 'ubuntu'
                 'redis-server'
               when 'redhat', 'centos', 'fedora', 'scientific', 'suse', 'amazon', 'rocky'
                 'redis'
               end

service service_name do
  action [:stop, :disable]
  only_if { service_name }
end
