require 'renee-core'
require 'renee-render'
require 'renee/version'

# Method for creating new Renee applications.
# @see http://reneerb.com
# @example
#     run Renee {
#       halt "hello renee"
#     }
def Renee(&blk)
  Renee::RichCore.new(&blk)
end

# Top-level Renee constant.
class Renee
  # Analogous to {Renee::Core}, but with all features enabled.
  # @see http://reneerb.com
  class RichCore < Renee::Core
    # Creates a new Renee application.
    # @yield The application definition.
    def initialize(&blk)
      super(Application, &blk)
    end

    # @private
    class Application < Renee::Core::Application
      include Renee::Render
    end
  end
end
