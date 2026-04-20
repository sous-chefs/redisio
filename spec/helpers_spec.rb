# frozen_string_literal: true

require 'spec_helper'
require_relative '../libraries/helpers'

RSpec.describe RedisioCookbook::Helpers do
  let(:helper_class) do
    Class.new do
      include RedisioCookbook::Helpers
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
end
