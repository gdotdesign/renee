require File.expand_path('../test_helper', __FILE__)

describe ReneeRender do
  describe "#render" do
    after  { remove_views }

    it "should allow rendering string with engine" do
      mock_app {
        path("/a") { get { inline! "<p>test</p>", :erb } }
        path("/b") { get { inline! "<p><%= foo %></p>", :erb, :locals => { :foo => "bar" } } }
        path("/c") { get { halt inline("<p><%= foo %></p>", :erb, :locals => { :foo => "bar" }) } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal "<p>test</p>", response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>", response.body
      get('/c')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>", response.body
    end # string, with engine

    it "should allow rendering template file with engine" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      mock_app {
        path("/a") { get { render! 'index', :haml } }
        path("/b") { get { render! 'foo', :haml, :locals => { :foo => "bar" } } }
        path("/c") { get { halt render('foo', :haml, :locals => { :foo => "bar" }) } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal "<p>test</p>\n", response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>\n", response.body
      get('/c')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>\n", response.body
    end # template, with engine

    it "should allow rendering template file with unspecified engine" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      mock_app {
        path("/a") { get { render! "index" } }
        path("/b") { get { render! "foo.haml", :locals => { :foo => "bar" } } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal "<p>test</p>\n", response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal "<p>bar</p>\n", response.body
    end # template, unspecified engine

    it "should allow rendering template file with engine and layout" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      create_view :layout, "%div.wrapper= yield", :haml
      mock_app {
        path("/a") { get { render! 'index', :haml, :layout => :layout } }
        path("/b") { get { render! 'foo', :layout => :layout, :locals => { :foo => "bar" } } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>test</p></div>\n}, response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>bar</p></div>\n}, response.body
    end # with engine and layout specified

    it "should allow rendering template with different layout engines" do
      create_view :index, "%p test", :haml
      create_view :foo,   "%p= foo", :haml
      create_view :base, "<div class='wrapper'><%= yield %></div>", :erb
      mock_app {
        path("/a") { get { render! 'index', :haml, :layout => 'base', :layout_engine => :erb } }
        path("/b") { get { render! 'foo', :haml, :layout => 'base', :locals => { :foo => "bar" } } }
      }
      get('/a')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>test</p>\n</div>}, response.body
      get('/b')
      assert_equal 200, response.status
      assert_equal %Q{<div class='wrapper'><p>bar</p>\n</div>}, response.body
    end # different layout and template engines

    it "should fail properly rendering template file with invalid engine" do
      create_view :index, "%p test", :haml
      mock_app {
        get { render! :fake, :index }
      }
      assert_raises(ReneeRender::TemplateNotFound) { get('/') }
    end # template, invalid engine

    it "should fail properly rendering missing template file with engine" do
      create_view :index, "%p test", :haml
      mock_app {
        get { render! :haml, :foo }
      }
      assert_raises(ReneeRender::TemplateNotFound) { get('/') }
    end # missing template, with engine
  end
end