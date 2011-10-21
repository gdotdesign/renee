# -*- coding: utf-8 -*-

require File.expand_path('../test_helper', __FILE__)

describe ReneeCore::EnvAccessors do
  it "should allow accessing the env" do
    @app = ReneeCore {
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
end
