class Renee
  class Core
    class Application
      # Collection of useful methods for routing within a {Renee::Core} app.
      module Routing
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
          chain(blk) do |with|
            p = p[1, p.size] if p[0] == ?/
            extension_part = detected_extension ? "|\\.#{Regexp.quote(detected_extension)}" : ""
            part(/^\/#{Regexp.quote(p)}(\/?|$)(?=\/|$#{extension_part})/, &with)
          end
        end

        # Like #path, but requires the entire path to be consumed.
        # @see #path
        def whole_path(p, &blk)
          chain(blk) do |with|
            path(p) { complete(&with) }
          end
        end

        # Like #path, but doesn't automatically match trailing-slashes.
        # @see #path
        def exact_path(p, &blk)
          chain(blk) do |with|
            p = p[1, part.size] if p[0] == ?/
            part(/^\/#{Regexp.quote(p)}/, &with)
          end
        end

        # Like #path, doesn't look for leading slashes.
        def part(p, &blk)
          chain(blk) do |with|
            p = /\/?#{Regexp.quote(p)}/ if p.is_a?(String)
            if match = env['PATH_INFO'][p]
              with_path_part(match) { with.call }
            end
          end
        end

        # Match parts off the path as variables. The parts matcher can conform to either a regular expression, or be an Integer, or
        # simply a String.
        # @param[Object] type the type of object to match for. If you supply Integer, this will only match integers in addition to
        #                     casting your variable for you.
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
          chain(blk) { |with| complex_variable(type, '/', 1, &with) }
        end
        alias_method :var, :variable

        def multi_variable(count, type = nil, &blk)
          chain(blk) { |with| complex_variable(type, '/', count, &with) }
        end
        alias_method :multi_var, :multi_variable
        alias_method :mvar, :multi_variable

        def repeating_variable(type = nil, &blk)
          chain(blk) { |with| complex_variable(type, '/', nil, &with) }
        end
        alias_method :glob, :repeating_variable

        # Match parts off the path as variables without a leading slash.
        # @see #variable
        # @api public
        def partial_variable(type = nil, &blk)
          chain(blk) {|with| complex_variable(type, nil, 1, &with) }
        end
        alias_method :part_var, :partial_variable

        # Match an extension.
        #
        # @example
        #   extension('html') { |path| halt [200, {}, path] }
        #
        # @api public
        def extension(ext, &blk)
          chain(blk) do |with|
            if detected_extension && match = detected_extension[ext]
              if match == detected_extension
                (ext_match = env['PATH_INFO'][/\/?\.#{match}/]) ?
                  with_path_part(ext_match, &with) : with.call
              end
            end
          end
        end
        alias_method :ext, :extension

        # Match no extension.
        #
        # @example
        #   no_extension { |path| halt [200, {}, path] }
        #
        # @api public
        def no_extension(&blk)
          chain(blk) {|with| with.call if detected_extension.nil? }
        end

        # Match any remaining path.
        #
        # @example
        #   remainder { |path| halt [200, {}, path] }
        #
        # @api public
        def remainder(&blk)
          chain(blk) { |with| with_path_part(env['PATH_INFO']) { |var| with.call(var) } }
        end
        alias_method :catchall, :remainder

        # Respond to a GET request and yield the block.
        #
        # @example
        #   get { halt [200, {}, "hello world"] }
        #
        # @api public
        def get(path = nil, &blk)
          request_method('GET', path, &blk)
        end

        # Respond to a POST request and yield the block.
        #
        # @example
        #   post { halt [200, {}, "hello world"] }
        #
        # @api public
        def post(path = nil, &blk)
          request_method('POST', path, &blk)
        end

        # Respond to a PUT request and yield the block.
        #
        # @example
        #   put { halt [200, {}, "hello world"] }
        #
        # @api public
        def put(path = nil, &blk)
          request_method('PUT', path, &blk)
        end

        # Respond to a DELETE request and yield the block.
        #
        # @example
        #   delete { halt [200, {}, "hello world"] }
        #
        # @api public
        def delete(path = nil, &blk)
          request_method('DELETE', path, &blk)
        end

        # Match only when the path has been completely consumed.
        #
        # @example
        #   delete { halt [200, {}, "hello world"] }
        #
        # @api public
        def complete(&blk)
          chain(blk) do |with|
            if env['PATH_INFO'] == '' || is_index_request
              with_path_part(env['PATH_INFO']) { with.call }
            end
          end
        end

        # Match variables within the query string.
        #
        # @param [Array, Hash] q
        #   Either an array or hash of things to match query string variables. If given
        #   an array, if you pass the values for each key as parameters to the block given.
        #   If given a hash, then every value must be able to #=== match each value in the query
        #   parameters for each key in the hash.
        #
        # @example
        #   query(:key => 'value') { halt [200, {}, "hello world"] }
        #
        # @example
        #   query(:key) { |val| halt [200, {}, "key is #{val}"] }
        #
        # @api public
        def query(q, &blk)
          chain(blk) do |with|
            case q
            when Hash  then q.any? {|k,v| !(v === request[k.to_s]) } ? return : with.call
            when Array then with.call(*q.map{|qk| request[qk.to_s] or return })
            else            query([q], &blk)
            end
          end
        end

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
          chain(blk) { |with| with.call if qs === env['QUERY_STRING'] }
        end

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
          if settings.variable_types.key?(type)
            settings.variable_types[type]
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
          chain(blk) do |with|
            path ? whole_path(path) { with.call } : complete { with.call } if env['REQUEST_METHOD'] == method
          end
        end
      end
    end
  end
end
