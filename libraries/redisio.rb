module RedisioHelper
  def recipe_eval
    sub_run_context = @run_context.dup
    sub_run_context.resource_collection = Chef::ResourceCollection.new
    begin
      original_run_context = @run_context
      @run_context = sub_run_context
      yield
    ensure
      @run_context = original_run_context
    end

    begin
      Chef::Runner.new(sub_run_context).converge
    ensure
      new_resource.updated_by_last_action(true) if sub_run_context.resource_collection.any?(&:updated?)
    end
  end

  def self.version_to_hash(version_string)
    version_array = version_string.split('.')
    version_array[2] = version_array[2].split('-')
    version_array.flatten!

    {
      major: version_array[0].include?(':') ? version_array[0].split(':')[1] : version_array[0],
      minor: version_array[1],
      tiny:  version_array[2],
      rc:    version_array[3],
    }
  end
end
