class MyTagsExtension < Radiant::Extension
  version "0.1"
  description "Working set of Radiant tags"
  url ""
  
  def activate
    Page.send :include, MyTags
  end
end