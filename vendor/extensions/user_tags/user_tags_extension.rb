class UserTagsExtension < Radiant::Extension
  version "0.5"
  description "Tags for accessing users, their attributes, and their roles."
  url ""

  def activate
    Page.send :include, UserTags
  end
end

