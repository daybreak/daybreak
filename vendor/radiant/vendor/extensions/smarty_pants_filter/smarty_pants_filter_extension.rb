begin
  require 'rubypants'
rescue LoadError
  # If rubypants gem is not available, use packaged version
  $LOAD_PATH.unshift "#{File.dirname(__FILE__)}/vendor/rubypants"
  retry
end

class SmartyPantsFilterExtension < Radiant::Extension
  version "1.0"
  description "Allows you to compose page parts or snippets using the SmartyPants text filter."
  url "http://daringfireball.net/projects/smartypants/"

  def activate
    SmartyPantsFilter
    Page.send :include, SmartyPantsTags
  end
end