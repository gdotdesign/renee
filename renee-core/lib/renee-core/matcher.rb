class Renee
  class Core
    class Matcher
      attr_accessor :name

      def initialize(matcher)
        @matcher = matcher
      end

      def on_error(&blk)
        @error_handler = blk
        self
      end

      def on_transform(&blk)
        @transform_handler = blk
        self
      end

      def transform(val)
        val
      end

      def halt_on_error!
        on_error { halt :bad_request }
        self
      end

      def [](val)
        match = nil
        case @matcher
        when Array
          match = nil
          @matcher.find { |m| match = m[val] }
        else
          if match = /^#{@matcher.to_s}/.match(val)
            match = [match[0]]
            match << @transform_handler.call(match.first) if @transform_handler
            match
          end
        end
        if match
          match
        elsif @error_handler
          raise ClientError.new("There was an error interpreting the value #{val.inspect} for #{name.inspect}", @error_handler)
        end
      end
    end
    IntegerMatcher = Matcher.new(/\d+/).on_transform{|v| Integer(v)}
  end
end