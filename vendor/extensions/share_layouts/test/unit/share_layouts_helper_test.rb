require File.dirname(__FILE__) + "/../test_helper"

class ShareLayoutsHelperTest < Test::Unit::TestCase
  include ShareLayouts::Helper
  fixtures :layouts
  test_helper :page
  attr_accessor :request, :response
  
MAIN_RESULT = <<-TEXT
<html>
  <head>
    <title>My Title</title>
  </head>
  <body>
    something
  </body>
</html>
TEXT

  def setup
    @page = ShareLayouts::RailsPage.new(page_params(:class_name => "ShareLayouts::RailsPage"))
    @content_for_layout = "something"
    @radiant_layout = layouts(:main).name
    @request = OpenStruct.new(:request_uri => "http://example.com/some/page")
  end
  
  def test_should_extract_content_captures_as_hash
    assert_equal({:body => "something"}, extract_captures)
    @content_for_sidebar = "sidebar"
    assert_equal({:body => "something", :sidebar => "sidebar"}, extract_captures)
  end
  
  def test_should_assign_layout_of_page
    assign_attributes!(@page)
    assert_equal @page._layout, layouts(:main)
  end
  
  def test_should_assign_page_title_from_instance_var
    @title = "My title"
    assign_attributes!(@page)
    assert_equal "My title", @page.title
  end
  
  def test_should_assign_page_title_from_capture
    @content_for_title = "My title"
    assign_attributes!(@page)
    assert_equal "My title", @page.title
  end
  
  def test_should_assign_breadcrumbs_from_instance_var
    @breadcrumbs = "bc"
    assign_attributes!(@page)
    assert_equal "bc", @page.breadcrumbs
  end    
  
  def test_should_assign_breadcrumbs_from_capture
    @content_for_breadcrumbs = "bc"
    assign_attributes!(@page)
    assert_equal "bc", @page.breadcrumbs
  end    

  def test_should_assign_empty_title_if_missing
    assert_nil @title
    assert_nil @content_for_title
    assign_attributes!(@page)
    assert_equal '', @page.title
  end
  
  def test_should_assign_empty_breadcrumbs_if_missing
    assert_nil @breadcrumbs
    assert_nil @content_for_breadcrumbs
    assign_attributes!(@page)
    assert_equal '', @page.title
  end

  def test_should_assign_request_uri
    assign_attributes!(@page)
    assert_equal '/some/page', @page.url
    assert_equal 'page', @page.slug
  end
  
  def test_should_render_page
    @title = "My Title"
    assert_equal MAIN_RESULT.strip, radiant_layout.strip
  end
end
