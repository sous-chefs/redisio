require 'spec_helper'

prefix = os[:family] == 'freebsd' ? '/usr/local' : ''

describe 'Redis' do
  it_behaves_like 'redis on port', 6379
end

describe file("#{prefix}/etc/redis/savetest.conf") do
  it { should be_file }

  ['save a', 'save b', 'save c'].each do |m|
    its(:content) { should match(m) }
  end
end
