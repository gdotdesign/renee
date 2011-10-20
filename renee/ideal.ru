$: << 'lib'

require 'renee'

class Application < Renee
  attr_reader :user

  def initialize
    app {
      @user = "new user"
      run Users
    }

    setup {
      
    }
  end
end

class Users < Application
  def initialize
    super
    app {
      halt "user is #{user.inspect}"
    }
  end
end

run Application.new