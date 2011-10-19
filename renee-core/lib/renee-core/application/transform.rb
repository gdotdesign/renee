class Renee
  class Core
    class Application
      module Transform
        # Transforms a value according to the rules specified by #register_variable_name.
        # @param [Symbol] name The name of the variable type.
        # @param [String] value The value to transform.
        # @return The transformed value or nil.
        def transform(type, value)
          if settings.variable_types.key?(type) and m = settings.variable_types[type][value]
            m.first == value ? m.last : nil
          end
        end
      end
    end
  end
end
