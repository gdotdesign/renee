class Renee
  class Core
    class Matcher
      def initialize(matcher, transformer, error_handler = nil)
        @matcher, @transformer, @error_handler = matcher, transformer, error_handler
      end

      def [](val)
        matcher = case @matcher
        when Array
          @matcher.find { |match| match.matcher[path] }
        else
          if match = @matcher.match(path)
            [match[0], @transformer[match[0]]]
          end
        end
        throw :halt, error_handler if @error_handler
      end
    end
    IntegerMatcher = Matcher.new(/\d+/, proc{|v| Integer(v)})
  end
end