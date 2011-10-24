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

# Top-level Renee constant
module Renee
  # @example
  #     Renee.core { path('/hello') { halt :ok } }
  def self.core(&blk)
    cls = Class.new(Renee::Core)
    cls.app(&blk) if blk
    cls
  end

  # The top-level class for creating core application.
  # For convience you can also used a method named #Renee
  # for decalaring new instances.
  class Core
    # Class methods that are included in new instances of {Core} 
    module ClassMethods
      include URLGeneration

      # The application block used to create your application.
      attr_reader :application_block

      # Provides a rack interface compliant call method. This method creates a new instance of your class and calls
      # #call on it.
      def call(env)
        new.call(env)
      end

      # Allows you to set the #application_block on your class.
      # @yield The application block
      def app(&app)
        @application_block = app
        setup do
          register_variable_type :integer, IntegerMatcher
          register_variable_type :int, :integer
        end
        self
      end

      # Runs class methods on your application.
      def setup(&blk)
        instance_eval(&blk)
        self
      end

      # The currently available variable types you've defined.
      def variable_types
        @variable_types ||= {}
      end

      # Registers a new variable type for use within {Renee::Core::Routing#variable} and others.
      # @param [Symbol] name The name of the variable.
      # @param [Regexp] matcher A regexp describing what part of an arbitrary string to capture.
      # @return [Renee::Core::Matcher] A matcher
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
end
