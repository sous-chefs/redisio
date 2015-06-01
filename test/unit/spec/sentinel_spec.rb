# Encoding: utf-8

require_relative 'spec_helper'

# the runlist came from test-kitchen's default suite
describe 'sentinel recipes' do
  recipes = %w(default enable sentinel sentinel_enable).map { |r| "redisio::#{r}" }

  # pick an arbitrary OS; just for fauxhai to provide some values
  it 'creates a default sentinel instance' do
    chef_run = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(*recipes) # *splat operator for array to vararg
    expect(chef_run).to run_redisio_sentinel('redis-sentinels').with(
      sentinels: [{
        "sentinel_port"=>"26379",
        "name"=>"mycluster",
        "masters" => [{"master_name"=>"mycluster_master", "master_ip"=>"127.0.0.1", "master_port"=>"6379"}]
        }]
    )
  end

  it 'creates a specified sentinel instance' do
    chef_run = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
      node.set['redisio']['sentinels'] = [{
          "sentinel_port"=>"1234",
          "name"=>"sentinel-test-params",
          "master_ip"=>"5.6.7.8",
          "master_port"=>9123
      }]
    end.converge(*recipes) # *splat operator for array to vararg
    expect(chef_run).to run_redisio_sentinel('redis-sentinels').with(sentinels: [{"sentinel_port"=>"1234", "name"=>"sentinel-test-params", "master_ip"=>"5.6.7.8", "master_port"=>9123}])
  end

  it 'should not create a sentinel instance' do
    chef_run = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
      node.set['redisio']['sentinels'] = []
    end.converge(*recipes) # *splat operator for array to vararg
    expect(chef_run).to run_redisio_sentinel('redis-sentinels').with(sentinels: [])
  end

end
