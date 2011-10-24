module Renee
  class Core
    # A module that defines useful Rack interaction methods.
    module RackInteraction
      # Creates an ad-hoc Rack application within the context of a Rack::Builder.
      # @yield The block to be used to instantiate the `Rack::Builder`.
      #
      # @example
      #     get { halt build { use Rack::ContentLength; run proc { |env| Rack::Response.new("Hello!").finish } } }
      #
      def build(&blk)
        run Rack::Builder.new(&blk).to_app
      end

      # Creates an ad-hoc Rack application within the context of a Rack::Builder that immediately halts when done.
      # @param (see #build)
      #
      # @example
      #     get { halt build { use Rack::ContentLength; run proc { |env| Rack::Response.new("Hello!").finish } } }
      #
      def build!(&blk)
        run! build(&blk)
      end

      # Runs a rack application. You must either use `app` or `blk`.
      # @param [#call] app The application to call.
      # @yield [env] The block to yield to
      #
      #
      # @example
      #     get { halt run proc { |env| Renee::Core::Response.new("Hello!").finish } }
      #
      def run(app = nil, &blk)
        raise "You cannot supply both a block and an app" unless app.nil? ^ blk.nil?
        (app || blk).call(env)
      end

      # Runs a rack application and halts immediately.
      # @param (see #run)
      #
      # @see #run!
      # @example
      #     get { run proc { |env| Renee::Core::Response.new("Hello!").finish } }
      #
      def run!(app = nil, &blk)
        halt run(app, &blk)
      end
    end
  end
end