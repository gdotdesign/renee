require 'rack'
require 'renee_core/matcher'
require 'renee_core/settings'
require 'renee_core/response'
require 'renee_core/application'
require 'renee_core/url_generation'
require 'renee_core/exceptions'

# The top-level class for creating core application.
# For convience you can also used a method named #Renee
# for decalaring new instances.
#
# @example
#     ReneeCore.new { path('/hello') { halt :ok } }
#
class ReneeCore
  include URLGeneration

  VERSION = RENEE_CORE_VERSION

  # The application block used to initialize this application.
  attr_reader :application_block
  # The {Settings} object used to initialize this application. 
  attr_reader :settings

  # @param [Proc] application_block The block of code that will be executed on each invocation of call #call.
  #                                 Each time #call is called, a new instance of {ReneeCore::Application} will
  #                                 be created. The block given will be #instance_eval 'd within
  #                                 the context of that new instance.
  #
  def initialize(&application_block)
    @application_block = application_block
  end

  def settings
    @settings ||= Settings.new
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

  def app(&application_block)
    @application_block = application_block
  end

  ##
  # Configure settings for your Renee application. Accepts a settings file path
  # or a block containing the configuration settings.
  #
  # @example
  #  ReneeCore.new { ... }.setup { views_path "./views" }
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

  def self.base_application_class
    Application
  end

  private
  def application_class
    @application_class ||= begin
      app_cls = Class.new(self.class.base_application_class)
      settings.includes.each { |inc| app_cls.send(:include, inc) }
      app_cls
    end
  end
end
