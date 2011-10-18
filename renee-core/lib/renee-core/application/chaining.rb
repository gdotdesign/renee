require 'set'

class Renee
  class Core
    class Application
      module Chaining
        class ChainingProxy
          def initialize(target, proxy_blk)
            @target, @proxy_blk, @calls = target, proxy_blk, []
          end

          def method_missing(m, *args, &blk)
            @calls << [m, *args]
            if blk
              ret = nil
              @proxy_blk.call(proc do |*inner_args|
                callback = proc do |*callback_args|
                  inner_args.concat(callback_args)
                  if @calls.size == 0
                    blk.call(*inner_args)
                  else
                    call = @calls.shift
                    ret = @target.send(call.at(0), *call.at(1), &callback)
                  end
                end
                call = @calls.shift
                ret = @target.send(call.at(0), *call.at(1), &callback)
              end)
              ret
            else
              self
            end
          end
        end

        def chain(blk, &proxy)
          blk ? yield(blk) : ChainingProxy.new(self, proxy)
        end
      end
    end
  end
end