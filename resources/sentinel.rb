actions :run

default_action :run

# Configuration attributes
attribute :version, kind_of: String
attribute :base_piddir, kind_of: String, default: '/var/run/redis'
attribute :user, kind_of: String, default: 'redis'

attribute :sentinel_defaults, kind_of: Hash
attribute :sentinels, kind_of: Array
