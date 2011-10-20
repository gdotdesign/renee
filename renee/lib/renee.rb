require 'renee_core'
require 'renee_render'

# Method for creating new Renee applications.
# @see http://reneerb.com
# @example
#     run Renee {
#       halt "hello renee"
#     }
def Renee(&blk)
  Renee.new(&blk)
end

# Top-level Renee constant.
class Renee < ReneeCore

  VERSION = RENEE_CORE_VERSION

  def self.base_application_class
    Application
  end

  # Creates a new Renee application.
  # @yield The application definition.
  def initialize(&blk)
    super(&blk)
  end

  # @private
  class Application < ReneeCore::Application
    include ReneeRender
  end
end
