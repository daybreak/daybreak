class RemarkableExtension < Radiant::Extension
  version "0.1"
  description "Adds a remarks field to select page types."
  url ""

  def activate
    Remarkable
    Note
  end
end
#TODO: make use of facets.parts rather than fields.
#TODO: in general use text filters (page_parts) over textarea fields

