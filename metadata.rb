name             'redisio'
maintainer       'Brian Bianco'
maintainer_email 'brian.bianco@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures redis'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.4.3'
%w[ debian ubuntu centos redhat fedora scientific suse amazon].each do |os|
  supports os
end
source_url      'https://github.com/brianbianco/redisio'	if respond_to?(:source_url)
issues_url       'https://github.com/brianbianco/redisio/issues'	if respond_to?(:issues_url)

recipe "redisio::default", "This recipe is used to install the prequisites for building and installing redis, as well as provides the LWRPs"
recipe "redisio::install", "This recipe is used to install redis"
recipe "redisio::configure", "This recipe is used to configure redis by creating the configuration files and init scripts"
recipe "redisio::sentinel", "This recipe is used to configure redis sentinels by creating the configuration files and init scripts"
recipe "redisio::sentinel_enable", "This recipe is used enable sentinel init scripts"
recipe "redisio::enable", "This recipe is used to start the redis instances and enable them in the default run levels"
recipe "redisio::disable", "this recipe is used to stop the redis instances and disable them in the default run levels"
recipe "redisio::redis_gem", "this recipe will install the redis ruby gem into the system ruby"

depends "ulimit", ">= 0.1.2"
depends "build-essential"
