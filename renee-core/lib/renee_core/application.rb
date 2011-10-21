require "renee_core/application/request_context"
require "renee_core/application/chaining"
require "renee_core/application/routing"
require "renee_core/application/responding"
require "renee_core/application/rack_interaction"
require "renee_core/application/transform"

class ReneeCore
  # This is the main class used to do the respond to requests. {Routing} provides route helpers.
  # {RequestContext} adds the RequestContext#call method to respond to Rack applications.
  # {Responding} defines the method Responding#halt which stops processing within a {ReneeCore::Application}.
  # It also has methods to interpret arguments to #halt and redirection response helpers.
  # {RackInteraction} adds methods for interacting with Rack.
  class Application
    include Chaining
    include RequestContext
    include Routing
    include Responding
    include RackInteraction
    include Transform

    attr_reader :application_block, :settings

    # @param [Proc] application_block The block that will be #instance_eval'd on each invocation to #call
    def initialize(settings, &application_block)
      @settings = settings
      @application_block = application_block
    end
  end
end
