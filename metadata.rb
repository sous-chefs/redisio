# frozen_string_literal: true

name              'redisio'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Provides custom resources for installing and managing Redis instances and Sentinels'
version           '7.2.5'
source_url        'https://github.com/sous-chefs/redisio'
issues_url        'https://github.com/sous-chefs/redisio/issues'
chef_version      '>= 16.0'

supports 'amazon', '>= 2023.0'
supports 'debian', '>= 12.0'
supports 'rocky', '>= 9.0'
supports 'ubuntu', '>= 22.04'

depends 'selinux'
