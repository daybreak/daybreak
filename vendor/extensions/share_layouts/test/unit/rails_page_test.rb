require File.dirname(__FILE__) + "/../test_helper"
require 'ostruct'

class RailsPageTest < Test::Unit::TestCase
  test_helper :render, :page
  def setup
    @page = ShareLayouts::RailsPage.new(page_params(:class_name => "ShareLayouts::RailsPage", :request_uri => "http://example.com/some/page"))
  end
  
  def test_should_assign_url_and_slug_from_request_uri
    @page.request_uri = "http://example.com/some/random/page"
    assert_equal "/some/random/page", @page.url
    assert_equal "page", @page.slug
  end
  
  def test_should_redefine_breadcrumbs_tag
    assert_respond_to @page, "tag:old_breadcrumbs"
    assert_respond_to @page, "tag:breadcrumbs"

    @page.breadcrumbs = "some breadcrumbs"
    @page.save!
    assert_renders "some breadcrumbs", "<r:breadcrumbs />"
  end
  
  def test_breadcrumb_should_equal_title
    @page.title = "My Page"
    assert_equal "My Page", @page.breadcrumb
  end
  
  def test_should_build_parts_from_hash
    hash = {:body => "body", :sidebar => "sidebar"}
    @page.build_parts_from_hash!(hash)
    assert_equal hash.keys.size, @page.parts.size
  end
end
