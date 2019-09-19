name              'redisio'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Installs and configures redis'
version           '4.0.0'
source_url        'https://github.com/sous-chefs/redisio'
issues_url        'https://github.com/sous-chefs/redisio/issues'
chef_version      '>= 14.0'

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

depends 'ulimit', '>= 0.1.2'
depends 'selinux_policy'
