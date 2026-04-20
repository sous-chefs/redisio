# frozen_string_literal: true

require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :error
end

def stub_service_inactive(service_name)
  stub_command("systemctl is-active --quiet #{service_name}").and_return(false)
end
