name             'redisio'
maintainer       'Sous Chefs'
maintainer_email 'help@sous-chefs.org'
license          'Apache-2.0'
description      'Installs and configures redis'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '3.0.0'

%w(
  amazon
  centos
  debian
  fedora
  redhat
  scientific
  suse
  ubuntu
).each do |os|
  supports os
end

source_url 'https://github.com/sous-chefs/redisio'
issues_url 'https://github.com/sous-chefs/redisio/issues'
chef_version '>= 13.0'

recipe 'redisio::default', 'This recipe is used to install the prequisites for building and installing redis, as well as provides the LWRPs'
recipe 'redisio::install', 'This recipe is used to install redis'
recipe 'redisio::configure', 'This recipe is used to configure redis by creating the configuration files and init scripts'
recipe 'redisio::sentinel', 'This recipe is used to configure redis sentinels by creating the configuration files and init scripts'
recipe 'redisio::sentinel_enable', 'This recipe is used enable sentinel init scripts'
recipe 'redisio::enable', 'This recipe is used to start the redis instances and enable them in the default run levels'
recipe 'redisio::disable', 'this recipe is used to stop the redis instances and disable them in the default run levels'
recipe 'redisio::redis_gem', 'this recipe will install the redis ruby gem into the system ruby'
recipe 'redisio::disable_os_default', 'This recipe is used to disable the default OS redis init script'

depends 'ulimit', '>= 0.1.2'
depends 'build-essential', '>= 5.0'
depends 'selinux_policy'
