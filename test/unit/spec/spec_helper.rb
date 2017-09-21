require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'
require 'chef-vault'

current_dir = File.dirname(File.expand_path(__FILE__))
Dir[File.join(current_dir, '../../../libraries/**/*.rb')].each { |f| require f }
Dir[File.join(current_dir, 'support/**/*.rb')].each { |f| require f }

at_exit { ChefSpec::Coverage.report! }

RSpec.configure do |config|
  config.version = '14.04'
  config.platform = 'ubuntu'
end
