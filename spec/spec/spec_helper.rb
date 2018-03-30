# Encoding: utf-8

require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

RSpec.configure do |config|
  config.version = '16.04'
  config.platform = 'ubuntu'
end
