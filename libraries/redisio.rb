module RedisioHelper
  def recipe_eval
    sub_run_context = @run_context.dup
    sub_run_context.resource_collection = Chef::ResourceCollection.new
    begin
      original_run_context, @run_context = @run_context, sub_run_context
      yield
    ensure
      @run_context = original_run_context
    end

    begin
      Chef::Runner.new(sub_run_context).converge
    ensure
      if sub_run_context.resource_collection.any?(&:updated?)
        new_resource.updated_by_last_action(true)
      end
    end
  end
end
