sentinel_instances = node['redisio']['sentinels']

if sentinel_instances.nil?
  sentinel_instances = [
    {
      'sentinel_port' => '26379',
      'name' => 'mycluster',
      'master_ip' => '127.0.0.1',
      'master_port' => '6379',
    },
  ]
end

execute 'reload-systemd-sentinel' do
  command 'systemctl daemon-reload'
  only_if { node['redisio']['job_control'] == 'systemd' }
  action :nothing
end

sentinel_instances.each do |current_sentinel|
  sentinel_name = current_sentinel['name']
  resource_name = if node['redisio']['job_control'] == 'systemd'
                    "service[redis-sentinel@#{sentinel_name}]"
                  else
                    "service[redis_sentinel_#{sentinel_name}]"
                  end
  resource = resources(resource_name)
  resource.action Array(resource.action)
  resource.action << :start
  if node['redisio']['job_control'] != 'systemd'
    resource.action << :enable
  else
    link "/etc/systemd/system/multi-user.target.wants/redis-sentinel@#{sentinel_name}.service" do
      to '/usr/lib/systemd/system/redis-sentinel@.service'
      notifies :run, 'execute[reload-systemd-sentinel]', :immediately
    end
  end
end
