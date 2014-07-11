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
      original_run_context, @run_context = @run_context, sub_run_context
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
    version_array[2] = version_array[2].split("-")
    version_array.flatten!
    version_hash = {
        :major => version_array[0],
        :minor => version_array[1],
        :tiny => version_array[2],
        :rc => version_array[3]
    }
  end

  def self.valid_oom_score_adjust(value)
    if value.to_i.between?(*self.oom_score_limits)
      value
    else
      nil
    end
  rescue
    nil
  end

  def self.oom_score_limits
    if self.old_kernel?
      [ -17, 15 ]
    else
      [ -1000, 1000 ]
    end
  end

  def self.oom_score_attribute
    if self.old_kernel?
      'oom_adj'
    else
      'oom_score_adj'
    end
  end

  def self.old_kernel?
    # node object is not always available to us here ... so use
    # a more direct way to obtain node['kernel']['release']
    @kernel_release ||= %x(uname -r).split('-').first
    Gem::Version.new(@kernel_release) < Gem::Version.new('2.6.29')
  end
end

