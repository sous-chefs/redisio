# Encoding: utf-8
require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

at_exit { ChefSpec::Coverage.report! }
