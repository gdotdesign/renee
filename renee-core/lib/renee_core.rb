require 'rack'
require 'renee_core/matcher'
require 'renee_core/chaining'
require 'renee_core/response'
require 'renee_core/url_generation'
require 'renee_core/exceptions'
require 'renee_core/rack_interaction'
require 'renee_core/request_context'
require 'renee_core/transform'
require 'renee_core/routing'
require 'renee_core/responding'
require 'renee_core/env_accessors'

# The top-level class for creating core application.
# For convience you can also used a method named #Renee
# for decalaring new instances.
#
# @example
#     ReneeCore { path('/hello') { halt :ok } }
#
class ReneeCore
  # The current version of ReneeCore
  VERSION = RENEE_CORE_VERSION

  module ClassMethods
    attr_reader :application_block

    include URLGeneration
    def call(env)
      new.call(env)
    end

    def app(&app)
      @application_block = app
      setup do
        register_variable_type :integer, IntegerMatcher
        register_variable_type :int, :integer
      end
      self
    end

    def setup(&blk)
      instance_eval(&blk)
      self
    end

    def variable_types
      @variable_types ||= {}
    end

    # Registers a new variable type for use within {ReneeCore::Routing#variable} and others.
    # @param [Symbol] name The name of the variable.
    # @param [Regexp] matcher A regexp describing what part of an arbitrary string to capture.
    # @return [ReneeCore::Matcher] A matcher
    def register_variable_type(name, matcher)
      matcher = case matcher
      when Matcher then matcher
      when Array   then Matcher.new(matcher.map{|m| variable_types[m]})
      when Symbol  then variable_types[matcher]
      else              Matcher.new(matcher)
      end
      matcher.name = name
      variable_types[name] = matcher
    end
  end

  class << self
    include ClassMethods
  end

  include Chaining
  include RequestContext
  include Routing
  include Responding
  include RackInteraction
  include Transform
  include EnvAccessors
end

def ReneeCore(&blk)
  cls = Class.new(ReneeCore)
  cls.app(&blk) if blk
  cls
end
