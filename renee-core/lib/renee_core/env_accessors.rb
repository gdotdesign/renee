module Renee
  class Core
    # Defines class-level methods for creating accessors for variables in your environment.
    module EnvAccessors
      InvalidEnvName = Class.new(RuntimeError)

      module ClassMethods
        
        def env_accessor(*attrs)
          env_reader(*attrs)
          env_writer(*attrs)
        end

        def env_reader(*attrs)
          instance_eval do
            env_attr_iter(*attrs) do |key, meth|
              define_method(meth) do
                env[key]
              end
            end
          end
        end

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

      def self.included(o)
        o.extend(ClassMethods)
      end
    end
  end
end
