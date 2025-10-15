redis = node['redisio']

redis['servers'].each do |current_server|
  server_name = current_server['name'] || current_server['port']
  resource_name = if node['redisio']['job_control'] == 'systemd'
                    "service[redis@#{server_name}]"
                  else
                    "service[redis#{server_name}]"
                  end
  resource = resources(resource_name)
  resource.action Array(resource.action)
  resource.action.push :start, :enable
end
