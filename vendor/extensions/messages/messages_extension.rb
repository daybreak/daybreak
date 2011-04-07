class MessagesExtension < Radiant::Extension
  version "0.1"
  description "Provides the management of series/messages for churches."
  url ""

  define_routes do |map|
		map.admin_series     'admin/series/:action/:id' , :controller => 'admin/series'
		map.admin_message    'admin/messages/:action/:id',:controller => 'admin/messages'
		map.message          'messages/:action/:id',      :controller => 'messages'
		map.message_feed     'message/feed/',             :controller => 'messages', :action => 'feed'
  end

  def activate
    tab "Content" do
      add_item "Series"  , "/admin/series"    
      add_item "Messages", "/admin/messages"
    end
    ActiveSupport::Inflector.inflections { |inflect| inflect.uncountable 'series' }
  end
end

