# frozen_string_literal: true

require 'spec_helper'
require_relative '../libraries/helpers'

RSpec.describe RedisioCookbook::Helpers do
  let(:helper_class) do
    Class.new do
      include RedisioCookbook::Helpers

      def platform_family?(*families)
        families.include?('debian')
      end
    end
  end

  subject(:helper) { helper_class.new }

  it 'parses Redis versions into a hash' do
    expect(helper.redis_version_to_hash('6:7.4.8-1rl1~noble1')).to eq(
      major: '7',
      minor: '4',
      tiny: '8',
      rc: '1rl1~noble1'
    )
  end

  it 'normalizes nested hashes to string keys' do
    expect(helper.deep_stringify_keys(foo: { bar: 1 })).to eq('foo' => { 'bar' => 1 })
  end

  it 'resolves valkey package names on debian' do
    expect(helper.platform_package_names(server_implementation: 'valkey', include_sentinel: true)).to eq(
      %w(valkey-server valkey-tools valkey-sentinel)
    )
  end

  it 'builds valkey instance service names' do
    expect(helper.redis_service_name('6379', server_implementation: 'valkey')).to eq('valkey@6379')
    expect(helper.sentinel_service_name('cluster', server_implementation: 'valkey')).to eq('valkey-sentinel@cluster')
  end
end
