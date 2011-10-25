module Renee
  class Core
    # Defines class-level methods for creating accessors for variables in your environment.
    module EnvAccessors

      # Exception for attempting to define an env accessor cannot be written as a method name.
      # @example
      #   env_accessor "current.user" # raises InvalidEnvName
      #   env_accessor "current.user" => :current_user # this works
      InvalidEnvName = Class.new(RuntimeError)

      # Class-methods included by this module.
      module ClassMethods

        # Defines getters and setters for a list of attributes. If the attributes cannot easily be expressed, use the
        # hash-syntax for defining them.
        # @example
        #   env_accessor "some_value" # will define methods to read and write env['some_value']
        #   env_accessor "current.user" => :current_user will define methods to read and write env['current.user']
        def env_accessor(*attrs)
          env_reader(*attrs)
          env_writer(*attrs)
        end

        # Defines getters for a list of attributes.
        # @see env_accessor
        def env_reader(*attrs)
          instance_eval do
            env_attr_iter(*attrs) do |key, meth|
              define_method(meth) do
                env[key]
              end
            end
          end
        end

        # Defines setters for a list of attributes.
        # @see env_accessor
        def env_writer(*attrs)
          instance_eval do
            env_attr_iter(*attrs) do |key, meth|
              define_method("#{meth}=") do |val|
                env[key] = val
              end
            end
          end
        end

        private
        def env_attr_iter(*attrs)
          attrs.each do |a|
            case a
            when Hash
              a.each do |k, v|
                yield k, v
              end
            else
              raise InvalidEnvName, "Called env attr for #{a.inspect}, to use this, call your env method like this. env_reader #{a.inspect} => #{a.to_s.gsub(/-\./, '_').to_sym.inspect}" if a.to_s[/[-\.]/]
              yield a, a.to_sym
            end
          end
        end
      
      end

      # @private
      def self.included(o)
        o.extend(ClassMethods)
      end
    end
  end
end
