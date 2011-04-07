require File.dirname(__FILE__) + '/../test_helper'

class CalendarExtensionTest < Test::Unit::TestCase
  
  # Replace this with your real tests.
  def test_this_extension
    flunk
  end
  
  def test_initialization
    assert_equal RADIANT_ROOT + '/vendor/extensions/calendar', CalendarExtension.root
    assert_equal 'Calendar', CalendarExtension.extension_name
  end
  
end
