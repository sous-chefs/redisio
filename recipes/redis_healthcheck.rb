#
# Cookbook Name:: sensu
# Recipe:: redis_healthcheck
#
# Copyright 2014, Autodesk Inc.
#
# This recipe is setting up the health check for two-node master-slave 
# redis cluster which will use a load balancer in front of two nodes.
# Loadbalancer will check the port 10240 with HTTP get to detect the active 
# node, which is the master.
#


package "xinetd" do
  action :install
end

service "xinetd" do
  action [:enable, :start]
end

template "/usr/sbin/redis-role.sh" do
  source "redis-role.sh"
  group "root"
  owner "root"
  mode "0755"
  action :create
end

execute "add_service_port_10240" do
  command "echo 'redischk        10240/tcp               # redis role monitoring' > /etc/services"
  not_if "grep '10240' /etc/services  | grep redischk" 
  notifies :restart, "service[xinetd]", :delayed
end

template "/etc/xinetd.d/redischk" do
  source "redischk"
  group "root"
  owner "root"
  mode "0600"
  action :create
  notifies :restart, "service[xinetd]", :immediately
end
