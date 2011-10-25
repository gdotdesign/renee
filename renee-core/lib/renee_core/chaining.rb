module Renee
  class Core
    # Module for creating chainable methods. To use this within your own modules, first `include Chaining`, then,
    # mark methods you want to be available with `chain_method :method_name`.
    # @example
    #    module MoreRoutingMethods
    #      include Chaining
    #      def other_routing_method
    #        # ..
    #      end
    #      chain_method :other_routing_method
    #
    module Chaining
      # @private
      class ChainingProxy
        def initialize(target, m, args)
          @target, @calls = target, []
          @calls << [m, args]
        end

        def method_missing(m, *args, &blk)
          @calls << [m, args]
          if blk.nil? && @target.class.private_method_defined?(:"#{m}_without_chain")
            self
          else
            inner_args = []
            ret = nil
            callback = proc do |*callback_args|
              inner_args.concat(callback_args)
              if @calls.size == 0
                return blk.call(*inner_args) if blk
              else
                call = @calls.shift
                ret = @target.send(call.at(0), *call.at(1), &callback)
              end
            end
            call = @calls.shift
            ret = @target.send(call.at(0), *call.at(1), &callback)
            ret
          end
        end
      end

      # @private
      module ClassMethods
        def chain_method(*methods)
          methods.each do |m|
            class_eval <<-EOT, __FILE__, __LINE__ + 1
              alias_method :#{m}_without_chain, :#{m}
              def #{m}(*args, &blk)
                blk.nil? ? ChainingProxy.new(self, #{m.inspect}, args) : #{m}_without_chain(*args, &blk)
              end
              private :#{m}_without_chain
            EOT
          end
        end
      end

      def self.included(o)
        o.extend(ClassMethods)
      end
    end
  end
end
