module Renee
  class Core
    # Class used for variable matching.
    class Matcher
      attr_accessor :name

      # @param [Regexp] matcher The regexp matcher to determine what is part of the variable.
      def initialize(matcher,)
        @matcher = matcher
      end

      # Used to specific the error handler if the matcher doesn't match anything. By default, there is no error handler.
      # @yield The block to be executed it fails to match.
      def on_error(&blk)
        @error_handler = blk
        self
      end

      # Used to transform the value matched.
      # @yield TODO
      def on_transform(&blk)
        @transform_handler = blk
        self
      end

      def on_error?(&blk)
        @error_handler1 = blk
        self
      end

      # Convienence method to creating halting error handler.
      # @param [Symbol, Integer] error_code The HTTP code to halt with.
      # @see #interpret_response
      def raise_on_error!(error_code = :bad_request)
        on_error { halt error_code }
        self
      end

      # Matcher for string
      # @param [String] val The value to attempt to match on.
      # @raise [ClientError] If the match fails to match and there is an error handler defined.
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
        else
          if @error_handler1
            &@error_handler1
          end
          if @error_handler
            raise ClientError.new("There was an error interpreting the value #{val.inspect} for #{name.inspect}", &@error_handler)
          end
      end
    end

    # Matcher for Integers
    IntegerMatcher = Matcher.new(/\d+/).on_transform{|v| Integer(v)}
  end
end
