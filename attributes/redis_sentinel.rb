# Cookbook Name:: redisio
# Attribute::default
#
# Copyright 2013, Rackspace Hosting <ryan.cleere@rackspace.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['redisio']['sentinel_defaults'] = {
  'user'                    => 'redis',
  'configdir'               => '/etc/redis',
  'sentinel_port'           => 26379,
  'monitor'                 => nil,
  'down-after-milliseconds' => 30000,
  'can-failover'            => 'yes',
  'parallel-syncs'          => 1,
  'failover-timeout'        => 900000
}

default['redisio']['sentinels'] = []

