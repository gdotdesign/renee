class ReneeCore
  module EnvAccessors
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
          env_key = a
          attr_method = a.to_s.gsub(/-\./, '_').downcase
          yield env_key, attr_method
        end
      end
      
    end

    def self.included(o)
      o.extend(ClassMethods)
    end
  end
end