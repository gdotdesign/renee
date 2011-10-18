require File.expand_path('../test_helper', __FILE__)

describe Renee::Core::Matcher do
  it "should transform variables" do
    mock_app {
      var :symbol do |i|
        halt i.inspect
      end
    }.setup {
      register_variable_type(:symbol, /[a-z_]+/).on_transform{|v| v.to_sym}
    }
    get '/test'
    assert_equal ":test", response.body
  end

  it "should halt on errors if told to" do
    mock_app {
      var :symbol do |i|
        halt i.inspect
      end
    }.setup {
      register_variable_type(:symbol, /[a-z_]+/).on_transform{|v| v.to_sym}.halt_on_error!
    }
    get '/123'
    assert_equal 400, response.status
  end
end


