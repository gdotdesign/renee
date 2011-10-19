require File.expand_path('../test_helper', __FILE__)

describe "Route::Settings#include" do
  it "should allow the inclusion of arbitrary modules" do
    type = { 'Content-Type' => 'text/plain' }
    @app = Renee::Core.new {
      halt :ok if respond_to?(:hi)
    }.setup {
      include Module.new { def hi; end }
    }
    get '/'
    assert_equal 200,   response.status
  end
end