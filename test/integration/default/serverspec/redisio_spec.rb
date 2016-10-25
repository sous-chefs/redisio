require 'spec_helper'

describe 'Redis' do
  it_behaves_like 'redis on port', 6379
end

if os[:family] == 'freebsd'
  describe file('/usr/local/etc/redis/savetest.conf') do
    it { should be_file }

    ['save a', 'save b', 'save c'].each do |m|
      its(:content) { should match(m) }
    end
  end
else
  describe file('/etc/redis/savetest.conf') do
    it { should be_file }

    ['save a', 'save b', 'save c'].each do |m|
      its(:content) { should match(m) }
    end
  end
end
