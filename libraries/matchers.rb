# cookbook/libraries/matchers.rb

if defined?(ChefSpec)
  ChefSpec.define_matcher(:redisio_configure)
  ChefSpec.define_matcher(:redisio_sentinel)
  def run_redisio_configure(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new('redisio_configure', :run, resource_name)
  end

  def run_redisio_sentinel(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new('redisio_sentinel', :run, resource_name)
  end
end
