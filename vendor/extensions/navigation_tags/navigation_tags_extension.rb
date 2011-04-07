class NavigationTagsExtension < Radiant::Extension
  version "0.1"
  description "Provides tags for generating navigation markup."
  url ""

  def activate
    Page.send :include, NavigationTags
  end
end

