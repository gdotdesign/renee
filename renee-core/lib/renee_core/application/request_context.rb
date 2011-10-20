class ReneeCore
  class Application
    # This module deals with the Rack#call compilance. It defines #call and also defines several critical methods
    # used by interaction by other application modules.
    module RequestContext
      attr_reader :env, :request, :detected_extension, :is_index_request
      alias_method :is_index_request?, :is_index_request

      # Provides a rack interface compliant call method.
      # @param[Hash] env The rack environment.
      def call(env)
        @env, @request = env, Rack::Request.new(env)
        @detected_extension = env['PATH_INFO'][/\.([^\.\/]+)$/, 1]
        @is_index_request = env['PATH_INFO'][/^\/?$/]
        # TODO clear template cache in development? `template_cache.clear`
        catch(:halt) do
          begin
            instance_eval(&application_block)
          rescue ClientError => e
            e.response ? instance_eval(&e.response) : halt("There was an error with your request", 400)
          end
          ReneeCore::Response.new("Not found", 404).finish
        end
      end # call
    end
  end
end
