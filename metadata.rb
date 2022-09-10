name              'redisio'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Installs and configures redis'
version           '6.3.0'
source_url        'https://github.com/sous-chefs/redisio'
issues_url        'https://github.com/sous-chefs/redisio/issues'
chef_version      '>= 16'

%w(
  amazon
  centos
  debian
  fedora
  redhat
  rocky
  scientific
  suse
  ubuntu
).each do |os|
  supports os
end

depends 'selinux'
