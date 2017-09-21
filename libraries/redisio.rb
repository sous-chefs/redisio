#
# Cookbook Name:: redisio
# Resource::install
#
# Copyright 2013, Brian Bianco <brian.bianco@gmail.com>
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

module RedisioHelper
  def recipe_eval
    sub_run_context = @run_context.dup
    sub_run_context.resource_collection = Chef::ResourceCollection.new
    begin
      original_run_context = @run_context
      @run_context = sub_run_context
      yield
    ensure
      @run_context = original_run_context
    end

    begin
      Chef::Runner.new(sub_run_context).converge
    ensure
      if sub_run_context.resource_collection.any?(&:updated?)
        new_resource.updated_by_last_action(true)
      end
    end
  end

  def self.version_to_hash(version_string)
    version_array = version_string.split('.')
    version_array[2] = version_array[2].split('-')
    version_array.flatten!

    {
      major: version_array[0].include?(':') ? version_array[0].split(':')[1] : version_array[0],
      minor: version_array[1],
      tiny: version_array[2],
      rc: version_array[3]
    }
  end

  # Load password from vault or data bag
  #
  # @param [Hash] opts defines where to get the secret
  # @option opts [String] :chef_vault_name chef vault name to load secret from
  # @option opts [String] :chef_vault_item chef vault item to load secret from
  # @option opts [String] :chef_vault_key chef vault key to load secret from
  # @option opts [String] :data_bag_name data bag name to load secret from
  # @option opts [String] :data_bag_item data bag item to load secret from
  # @option opts [String] :data_bag_key data bag key to load secret from
  # @option opts [String] :data_bag_secret path to secret to decrypt data bag item
  def self.load_secret(opts = {})
    if opts['chef_vault_name'] && opts['chef_vault_item'] && opts['chef_vault_key']
      Chef::Log.info(
        "Loading secret from vault #{opts['chef_vault_name']} / #{opts['chef_vault_item']} / #{opts['chef_vault_key']}"
      )

      require 'chef-vault'

      item = ChefVault::Item.load(opts['chef_vault_name'], opts['chef_vault_item'])
      item[opts['chef_vault_key']]
    elsif opts['data_bag_name'] && opts['data_bag_item'] && opts['data_bag_key']
      Chef::Log.info(
        "Loading secret from encrypted data bag #{opts['data_bag_name']} / #{opts['data_bag_item']} / #{opts['data_bag_key']}"
      )
      secret = if opts['data_bag_secret']
                 Chef::EncryptedDataBagItem.load_secret(opts['data_bag_secret'])
               end
      bag = Chef::EncryptedDataBagItem.load(
        opts['data_bag_name'],
        opts['data_bag_item'],
        secret
      )
      bag[opts['data_bag_key']]
    else
      Chef::Log.info('Not loading secret from vault or encrypted data bag')
      nil
    end
  end
end
