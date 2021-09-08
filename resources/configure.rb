actions :run
unified_mode true
default_action :run

# Configuration attributes
attribute :version, kind_of: String
attribute :base_piddir, kind_of: String, default: '/var/run/redis'
attribute :user, kind_of: String, default: 'redis'
attribute :group, kind_of: String, default: 'redis'

attribute :default_settings, kind_of: Hash
attribute :servers, kind_of: Array
