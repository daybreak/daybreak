class RecordTagsExtension < Radiant::Extension
  version "0.5"
  description "Adds tags for displaying database records.  A natural front end for custom, back-end models."
  url ""
  
  def activate
    Page.send :include, RecordTags
  end
end