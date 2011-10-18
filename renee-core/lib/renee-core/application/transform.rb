class Renee
  class Core
    class Application
      module Transform
        def transform(type, value)
          if settings.variable_types.key?(type) and m = settings.variable_types[type][value]
            m.first == value ? m.last : nil
          end
        end
      end
    end
  end
end
