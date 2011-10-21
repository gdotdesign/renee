require 'renee_core'
require 'renee_render'

# Method for creating new Renee applications.
# @see http://reneerb.com
# @example
#     run Renee {
#       halt "hello renee"
#     }
def Renee(&blk)
  Class.new(Renee).app(&blk)
end

# Top-level Renee constant.
class Renee < ReneeCore

  include ReneeRender

  # The current version of Renee
  VERSION = RENEE_CORE_VERSION
end
