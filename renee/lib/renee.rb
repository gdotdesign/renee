require 'renee_core'
require 'renee_render'

# Method for creating new Renee applications.
# @see http://reneerb.com
# @example
#     run Renee {
#       halt "hello renee"
#     }
def Renee(&blk)
  Class.new(Renee::Application).app(&blk)
end

# Top-level Renee constant.
module Renee
  class Application < Core
    include Renee::Render
  end
end
