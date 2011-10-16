require File.expand_path('../test_helper', __FILE__)

describe Renee::RichCore do
  it "should allow the inclusion of arbitrary modules" do
    r = Renee{
      respond_to?(:some_method) or raise
    }.setup { include Module.new { def some_method; end } }
    r.call(Rack::MockRequest.env_for('/'))
    assert true
  end
end
