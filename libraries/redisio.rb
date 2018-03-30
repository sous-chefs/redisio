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
      # rubocop:disable Style/IfUnlessModifier
      if sub_run_context.resource_collection.any?(&:updated?)
        new_resource.updated_by_last_action(true)
      end
      # rubocop:enable Style/IfUnlessModifier
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
  # @option opts [String] 'data_bag_name' data bag name to load secret from
  # @option opts [String] 'data_bag_item' data bag item to load secret from
  # @option opts [String] 'data_bag_key' item's key to load the secret from
  # @option opts [String] 'data_bag_secret' path to secret file to decrypt data bag item
  def self.load_secret(opts = {})
    # wont be able to load data bag unless these are set
    unless opts['data_bag_name'] && opts['data_bag_item']
      Chef::Log.info('Not loading secret from chef vault or data bag')
      return nil
    end

    # defaults for opts hash
    opts['data_bag_key'] ||= 'password'
    opts['data_bag_secret'] ||= Chef::Config[:encrypted_data_bag_secret]

    require 'chef-vault'

    case ChefVault::Item.data_bag_item_type(opts['data_bag_name'], opts['data_bag_item'])
    when :vault
      Chef::Log.info(
        "Loading secret from vault #{opts['data_bag_name']} / "\
        "#{opts['data_bag_item']} / #{opts['data_bag_key']}"
      )
      item = ChefVault::Item.load(opts['data_bag_name'], opts['data_bag_item'])
      item[opts['data_bag_key']]
    when :encrypted
      Chef::Log.info(
        "Loading secret from encrypted data bag item #{opts['data_bag_name']} "\
        "/ #{opts['data_bag_item']} / #{opts['data_bag_key']}"
      )
      bag = Chef::EncryptedDataBagItem.load(
        opts['data_bag_name'],
        opts['data_bag_item'],
        Chef::EncryptedDataBagItem.load_secret(opts['data_bag_secret'])
      )
      bag[opts['data_bag_key']]
    when :normal
      Chef::Log.warn(
        "Loading secret from unencrypted data bag item #{opts['data_bag_name']}"\
        " / #{opts['data_bag_item']} / #{opts['data_bag_key']}"
      )
      bag = Chef::DataBagItem.load(opts['data_bag_name'], opts['data_bag_item'])
      bag[opts['data_bag_key']]
    end
  end
end
