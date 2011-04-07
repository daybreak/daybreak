module Admin::PositionsHelper
  include ActionView::Helpers::UrlHelper
  include Admin::PersonsHelper

  def link_to_position(position)
    link_to_unless(position.new_record?, (position.subordinates.any? ? "#{position.subordinates.length} #{position.subordinates.length == 1 ? 'person' : 'people'}" : "no one"), :controller => "/admin/positions", :action => "edit", :id => position.id)
  end
end

