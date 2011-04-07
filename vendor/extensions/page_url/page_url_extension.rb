class PageUrlExtension < Radiant::Extension
  version "1.0"
  description "Provides a full_path method to @page"
  url ""

  def activate
    Page.send :include, PageUrl::PageExtensions
  end

  def deactivate
  end
end

