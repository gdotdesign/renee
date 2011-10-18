class Renee
  class Core
    class ClientError < StandardError
      attr_reader :response
      def initialize(message, response = nil)
        super(message)
        @response = response
      end
    end
  end
end
