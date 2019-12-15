require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

RSpec.configure do |config|
  config.version = '14.04'
  config.platform = 'ubuntu'
end
