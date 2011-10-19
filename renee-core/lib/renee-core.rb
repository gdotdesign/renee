require 'rack'
require 'renee-core/version'
require 'renee-core/matcher'
require 'renee-core/settings'
require 'renee-core/response'
require 'renee-core/application'
require 'renee-core/url_generation'
require 'renee-core/exceptions'

# Top-level Renee constant
class Renee
  # The top-level class for creating core application.
  # For convience you can also used a method named #Renee
  # for decalaring new instances.
  #
  # @example
  #     Renee::Core.new { path('/hello') { halt :ok } }
  #
  class Core
    include URLGeneration

    # The application block used to initialize this application.
    attr_reader :application_block
    # The {Settings} object used to initialize this application. 
    attr_reader :settings

    # @param [Proc] application_block The block of code that will be executed on each invocation of call #call.
    #                                 Each time #call is called, a new instance of {Renee::Core::Application} will
    #                                 be created. The block given will be #instance_eval 'd within
    #                                 the context of that new instance.
    #
    def initialize(base_application_class = Application, &application_block)
      @base_application_class = base_application_class
      @application_block = application_block
      @settings = Settings.new
    end

    # This is a rack-compliant `Rack#call`.
    #
    # @param [Hash] env The environment hash.
    #
    # @return [Array] A rack compliant return.
    #
    # @see http://rack.rubyforge.org/doc/SPEC.html
    #
    def call(env)
      application_class.new(settings, &application_block).call(env)
    end

    ##
    # Configure settings for your Renee application. Accepts a settings file path
    # or a block containing the configuration settings.
    #
    # @example
    #  Renee::Core.new { ... }.setup { views_path "./views" }
    #
    # @api public
    def setup(path = nil, &blk)
      raise "You cannot supply both an argument and a block to the method." unless path.nil? ^ blk.nil?
      case path
      when nil      then settings.instance_eval(&blk)
      when Settings then @settings = path
      when String   then File.exist?(path) ? settings.instance_eval(File.read(path), path, 1) : raise("The settings file #{path} does not exist")
      else               raise "Could not setup with #{path.inspect}"
      end
      self
    end

    private
    def application_class
      @application_class ||= begin
        app_cls = Class.new(@base_application_class)
        settings.includes.each { |inc| app_cls.send(:include, inc) }
        app_cls
      end
    end
  end
end