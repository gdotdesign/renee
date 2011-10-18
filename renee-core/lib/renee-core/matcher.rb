class Renee
  class Core
    class Matcher
      def initialize(matcher, transformer, error_handler = nil)
        @matcher, @transformer, @error_handler = matcher, transformer, error_handler
      end

      def [](path, prefix)
        matcher = case @matcher
        when Array
          @matcher.find { |match| match[path, prefix] }
        else
          if match = /^#{Regexp.quote(prefix)}#{@matcher.to_s}/.match(path)
            [match[0], @transformer[match[0][prefix.size, match[0].size]]]
          end
        end
        if matcher.nil? && @error_handler
          throw :halt, error_handler
        else
          matcher
        end
      end
    end
    IntegerMatcher = Matcher.new(/\d+/, proc{|v| Integer(v)})
  end
end