# -*- coding: utf-8 -*-

require File.expand_path('../test_helper', __FILE__)

describe Renee::Core::EnvAccessors do
  it "should allow accessing the env" do
    @app = Renee.core {
      self.test = 'hello'
      path('test').get do
        halt "test is #{test}"
      end
    }.setup {
      env_accessor :test
    }
    get '/test'
    assert_equal 200,   response.status
    assert_equal 'test is hello', response.body
  end

  it "should raise when you try to access weird env keys" do
    assert_raises(Renee::Core::EnvAccessors::InvalidEnvName) {
      @app = Renee.core {
        self.test_test = 'hello'
      }.setup {
        env_accessor "test.test"
      }
    }
  end

  it "should allow weird env keys if you map them" do
    @app = Renee.core {
      self.test_test = 'hello'
      path('test').get do
        halt "test is #{test_test}"
      end
    }.setup {
      env_accessor "test.test" => :test_test
    }
    get '/test'
    assert_equal 200,   response.status
    assert_equal 'test is hello', response.body
  end
end
