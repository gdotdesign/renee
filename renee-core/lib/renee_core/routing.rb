module Renee
  class Core
    # Collection of useful methods for routing within a {Renee::Core} app.
    module Routing
      include Chaining

      # Match a path to respond to.
      #
      # @param [String] p
      #   path to match.
      # @param [Proc] blk
      #   block to yield
      #
      # @example
      #   path('/')    { ... } #=> '/'
      #   path('test') { ... } #=> '/test'
      #
      #   path 'foo' do
      #     path('bar') { ... } #=> '/foo/bar'
      #   end
      #
      # @api public
      def path(p, &blk)
        p = p[1, p.size] if p[0] == ?/
        extension_part = detected_extension ? "|\\.#{Regexp.quote(detected_extension)}" : ""
        part(/^\/#{Regexp.quote(p)}(\/?|$)(?=\/|$#{extension_part})/, &blk)
      end
      chain_method :path

      # Like #path, but requires the entire path to be consumed.
      # @see #path
      def whole_path(p, &blk)
        path(p) { complete(&blk) }
      end
      chain_method :whole_path

      # Like #path, but doesn't automatically match trailing-slashes.
      # @see #path
      def exact_path(p, &blk)
        p = p[1, part.size] if p[0] == ?/
        part(/^\/#{Regexp.quote(p)}/, &blk)
      end
      chain_method :exact_path

      # Like #path, but doesn't look for leading slashes.
      def part(p, &blk)
        p = /\/?#{Regexp.quote(p)}/ if p.is_a?(String)
        if match = env['PATH_INFO'][p]
          with_path_part(match) { blk.call }
        end
      end
      chain_method :part

      # Match parts off the path as variables. The parts matcher can conform to either a regular expression, or be an Integer, or
      # simply a String.
      # @param[Object] type the type of object to match for. If you supply Integer, this will only match integers in addition to casting your variable for you.
      # @param[Object] default the default value to use if your param cannot be successfully matched.
      #
      # @example
      #   path '/' do
      #     variable { |id| halt [200, {}, id] }
      #   end
      #   GET /hey  #=> [200, {}, 'hey']
      #
      # @example
      #   path '/' do
      #     variable(:integer) { |id| halt [200, {}, "This is a numeric id: #{id}"] }
      #   end
      #   GET /123  #=> [200, {}, 'This is a numeric id: 123']
      #
      # @example
      #   path '/test' do
      #     variable { |foo, bar| halt [200, {}, "#{foo}-#{bar}"] }
      #   end
      #   GET /test/hey/there  #=> [200, {}, 'hey-there']
      #
      # @api public
      def variable(type = nil, &blk)
        complex_variable(type, '/', 1, &blk)
      end
      alias_method :var, :variable
      chain_method :variable, :var

      # Same as variable except you can match multiple variables with the same type.
      # @param [Range, Integer] count The number of parameters to capture.
      # @param [Symbol] type The type to use for match.
      def multi_variable(count, type = nil, &blk)
        complex_variable(type, '/', count, &blk)
      end
      alias_method :multi_var, :multi_variable
      alias_method :mvar, :multi_variable
      chain_method :multi_variable, :multi_var, :mvar

      # Same as variable except it matches indefinitely.
      # @param [Symbol] type The type to use for match.
      def repeating_variable(type = nil, &blk)
        complex_variable(type, '/', nil, &blk)
      end
      alias_method :glob, :repeating_variable
      chain_method :repeating_variable, :glob

      # Match parts off the path as variables without a leading slash.
      # @see #variable
      # @api public
      def partial_variable(type = nil, &blk)
        complex_variable(type, nil, 1, &blk)
      end
      alias_method :part_var, :partial_variable
      chain_method :partial_variable, :part_var

      # Match an extension.
      #
      # @example
      #   extension('html') { |path| halt [200, {}, path] }
      #
      # @api public
      def extension(ext, &blk)
        if detected_extension && match = detected_extension[ext]
          if match == detected_extension
            (ext_match = env['PATH_INFO'][/\/?\.#{match}/]) ?
              with_path_part(ext_match, &blk) : blk.call
          end
        end
      end
      alias_method :ext, :extension
      chain_method :extension, :ext

      # Match no extension.
      #
      # @example
      #   no_extension { |path| halt [200, {}, path] }
      #
      # @api public
      def no_extension(&blk)
        blk.call if detected_extension.nil?
      end
      chain_method :no_extension

      # Match any remaining path.
      #
      # @example
      #   remainder { |path| halt [200, {}, path] }
      #
      # @api public
      def remainder(&blk)
        with_path_part(env['PATH_INFO']) { |var| blk.call(var) }
      end
      alias_method :catchall, :remainder
      chain_method :remainder, :catchall

      # Respond to a GET request and yield the block.
      #
      # @example
      #   get { halt [200, {}, "hello world"] }
      #
      # @api public
      def get(path = nil, &blk)
        request_method('GET', path, &blk)
      end
      chain_method :get

      # Respond to a POST request and yield the block.
      #
      # @example
      #   post { halt [200, {}, "hello world"] }
      #
      # @api public
      def post(path = nil, &blk)
        request_method('POST', path, &blk)
      end
      chain_method :post

      # Respond to a PUT request and yield the block.
      #
      # @example
      #   put { halt [200, {}, "hello world"] }
      #
      # @api public
      def put(path = nil, &blk)
        request_method('PUT', path, &blk)
      end
      chain_method :put

      # Respond to a DELETE request and yield the block.
      #
      # @example
      #   delete { halt [200, {}, "hello world"] }
      #
      # @api public
      def delete(path = nil, &blk)
        request_method('DELETE', path, &blk)
      end
      chain_method :delete

      # Match only when the path has been completely consumed.
      #
      # @example
      #   complete { halt [200, {}, "hello world"] }
      #
      # @api public
      def complete(&blk)
        if env['PATH_INFO'] == '' || is_index_request
          with_path_part(env['PATH_INFO']) { blk.call }
        end
      end
      chain_method :complete

      # Match variables within the query string.
      #
      # @param [Array, Hash] q
      #   Either an array or hash of things to match query string variables. If given
      #   an array, if you pass the values for each key as parameters to the block given.
      #   If given a hash, then every value must be able to be matched by a registered type.
      #
      # @example
      #   query(:key => :integer) { |h| halt [200, {}, "hello world #{h[:key]}"] }
      #
      # @example
      #   query(:key) { |val| halt [200, {}, "key is #{val}"] }
      #
      # @api public
      def query(q, &blk)
        case q
        when Hash  then blk.call(Hash[q.map{|(k, v)| [k, transform(v, request[k.to_s]) || return]}])
        when Array then blk.call(*q.map{|qk| request[qk.to_s] or return })
        else            query([q], &blk)
        end
      end
      chain_method :query

      # Yield block if the query string matches.
      #
      # @param [String] qs
      #   The query string to match.
      #
      # @example
      #   path 'test' do
      #     query_string 'foo=bar' do
      #       halt [200, {}, 'matched']
      #     end
      #   end
      #   GET /test?foo=bar #=> 'matched'
      #
      # @api public
      def query_string(qs, &blk)
        blk.call if qs === env['QUERY_STRING']
      end
      chain_method :query_string

      private
      def complex_variable(type, prefix, count)
        matcher = variable_matcher_for_type(type)
        path = env['PATH_INFO'].dup
        vals = []
        var_index = 0
        variable_matching_loop(count) do
          path.start_with?(prefix) ? path.slice!(0, prefix.size) : break if prefix
          if match = matcher[path]
            path.slice!(0, match.first.size)
            vals << match.last
          end
        end
        return unless count.nil? || count === vals.size
        with_path_part(env['PATH_INFO'][0, env['PATH_INFO'].size - path.size]) do
          if count == 1
            yield(vals.first)
          else
            yield(vals)
          end
        end
      end

      def variable_matching_loop(count)
        case count
        when Range then count.max.times { break unless yield }
        when nil   then loop { break unless yield }
        else            count.times { break unless yield }
        end
      end

      def variable_matcher_for_type(type)
        if self.class.variable_types.key?(type)
          self.class.variable_types[type]
        else
          regexp = case type
          when nil, String
            detected_extension ?
              /(([^\/](?!#{Regexp.quote(detected_extension)}$))+)(?=$|\/|\.#{Regexp.quote(detected_extension)})/ :
              /([^\/]+)(?=$|\/)/
          when Regexp
            type
          else
            raise "Unexpected variable type #{type.inspect}"
          end
          proc do |path|
            if match = /^#{regexp.to_s}/.match(path)
              [match[0]]
            end
          end
        end
      end

      def with_path_part(part)
        old_path_info, old_script_name = env['PATH_INFO'], env['SCRIPT_NAME']
        script_part, env['PATH_INFO'] = old_path_info[0, part.size], old_path_info[part.size, old_path_info.size]
        env['SCRIPT_NAME'] += script_part
        yield script_part
        env['PATH_INFO'], env['SCRIPT_NAME'] = old_path_info, old_script_name
      end

      def request_method(method, path = nil, &blk)
        path ? whole_path(path) { blk.call } : complete { blk.call } if env['REQUEST_METHOD'] == method
      end
      chain_method :request_method
    end
  end
end
