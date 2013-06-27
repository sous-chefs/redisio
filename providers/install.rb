#
# Cookbook Name:: redisio
# Provider::install
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

action :run do
  @tarball = "#{new_resource.base_name}#{new_resource.version}.#{new_resource.artifact_type}"

  unless ( current_resource.version == new_resource.version || (redis_exists? && new_resource.safe_install) )
    Chef::Log.info("Installing Redis #{new_resource.version} from source")
    download
    unpack
    build
    install
  end
end

def download
  Chef::Log.info("Downloading redis tarball from #{new_resource.download_url}")
  remote_file "#{new_resource.download_dir}/#{@tarball}" do
    source new_resource.download_url
  end
end

def unpack
  install_dir = "#{new_resource.base_name}#{new_resource.version}"
  case new_resource.artifact_type
    when "tar.gz",".tgz"
      execute %(cd #{new_resource.download_dir} ; mkdir -p '#{install_dir}' ; tar zxf '#{@tarball}' --strip-components=1 -C '#{install_dir}')
    else
      raise Chef::Exceptions::UnsupportedAction, "Current package type #{new_resource.artifact_type} is unsupported"
  end
end

def build
  execute"cd #{new_resource.download_dir}/#{new_resource.base_name}#{new_resource.version} && make clean && make"
end

def install
  install_prefix = ""
  install_prefix = "PREFIX=#{new_resource.install_dir}" if new_resource.install_dir
  execute "cd #{new_resource.download_dir}/#{new_resource.base_name}#{new_resource.version} && make #{install_prefix} install"
  new_resource.updated_by_last_action(true)
end

def redis_exists?
  bin_path = "/usr/local/bin"
  bin_path = ::File.join(node['redisio']['install_dir'], 'bin') if node['redisio']['install_dir']
  redis_server = ::File.join(bin_path, 'redis-server')
  ::File.exists?(redis_server)
end

def version
  if redis_exists?
    bin_path = "/usr/local/bin"
    bin_path = ::File.join(node['redisio']['install_dir'], 'bin') if node['redisio']['install_dir']
    redis_server = ::File.join(bin_path, 'redis-server')
    redis_version = Mixlib::ShellOut.new("#{redis_server} -v")
    redis_version.run_command
    version = redis_version.stdout[/version (\d*.\d*.\d*)/,1] || redis_version.stdout[/v=(\d*.\d*.\d*)/,1]
    Chef::Log.info("The Redis server version is: #{version}")
    return version.gsub("\n",'')
  end
  nil
end

def load_current_resource
  @current_resource = Chef::Resource::RedisioInstall.new(new_resource.name)
  @current_resource.version(version)
  @current_resource
end
