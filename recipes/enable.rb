redis = node['redisio']

redis['servers'].each do |current_server|
  server_name = current_server['name'] || current_server['port']
  resource_name = if node['redisio']['job_control'] == 'systemd'
                    "redis@#{server_name}"
                  else
                    "redis#{server_name}"
                  end
  service resource_name do
    action [:start, :enable]
  end
end
