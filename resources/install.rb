actions :run
unified_mode true
default_action :run

# Installation attributes
attribute :version, kind_of: String
attribute :download_url, kind_of: String
attribute :download_dir, kind_of: String, default: Chef::Config[:file_cache_path]
attribute :artifact_type, kind_of: String, default: 'tar.gz'
attribute :base_name, kind_of: String, default: 'redis-'
attribute :safe_install, kind_of: [TrueClass, FalseClass], default: true
attribute :enable_tls, kind_of: [TrueClass, FalseClass], default: false

attribute :install_dir, kind_of: String, default: nil
