class Renee
  class Core
    # Used to indicate a client-error has occurred (e.g. 4xx)
    class ClientError < StandardError
      attr_reader :response

      # @param [String] message The message for this exception.
      # @yield The optional block to instance-eval in the case this error is raised.
      def initialize(message, &response)
        super(message)
        @response = response
      end
    end
  end
end
