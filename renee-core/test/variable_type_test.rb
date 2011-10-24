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
      register_variable_type(:symbol, /[a-z_]+/).on_transform{|v| v.to_sym}.raise_on_error!
    }
    get '/123'
    assert_equal 400, response.status
  end

  it "should allow custom error handling behaviour on values that don't match" do
    mock_app {
      var :symbol do |i|
        halt i.inspect
      end
    }.setup {
      register_variable_type(:symbol, /[a-z_]+/).on_transform{|v| v.to_sym}.on_error{|v| halt 500 }
    }
    get '/123'
    assert_equal 500, response.status
  end

  it "should allow composite variable types" do
    mock_app {
      path("plus10").var(:int_or_hex) do |i|
        halt "plus10: #{i + 10}"
      end
    }.setup {
      register_variable_type(:int, /[0-9]+/).on_transform{|v| Integer(v)}
      register_variable_type(:hex, /0x[0-9a-f]+/).on_transform{|v| v.to_i(16)}
      register_variable_type(:int_or_hex, [:hex, :int])
    }
    get '/plus10/123'
    assert_equal 'plus10: 133', response.body
    get '/plus10/0x7b'
    assert_equal 'plus10: 133', response.body
  end
end


