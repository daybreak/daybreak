require 'lib/events'

class EventsExtension < Radiant::Extension
  version "0.5"
  description "Adds tab for managing calendar events."
  url ""

  define_routes do |map|
    map.admin_event             'admin/events/:action/:id'             ,:controller => 'admin/events'
    map.admin_event_legacy      'admin/event/:action/:id'              ,:controller => 'admin/events' #For temporary backwards compatability (supporting links already on Google)
    map.admin_event_category    'admin/event_categories/:action/:id'   ,:controller => 'admin/event_categories'
    map.admin_recurrence        'admin/recurrences/:action/:id'        ,:controller => 'admin/recurrences'
    map.admin_registration      'admin/registrations/:action/:id'      ,:controller => 'admin/registrations'
    map.admin_resource_category 'admin/resource_categories/:action/:id',:controller => 'admin/resource_categories'
    map.admin_resource          'admin/resources/:action/:id'          ,:controller => 'admin/resources'

    map.registration  'registrations/:action/:id' ,:controller => 'registrations'
    map.invitation    'invitations/:action/:id'   ,:controller => 'invitations'
    map.evite         'evites/:action/:id'        ,:controller => 'invitations'

    map.event_request 'events/event_request/:id'  ,:controller => 'family/events', :action => 'event_request'

    RecurrenceCategory.find(:all).each do |cat|
      map.connect "#{cat.slug}/:action/:id", :controller => 'recurrences', :slug => cat.slug
    end
  end

  def activate
    production = ENV['RAILS_ENV'] == 'production'
  	Radiant::Config['events.event_request_notice_emails'] ||= "info@daybreakweb.com"
  	Event
    tab "Calendar" do
      add_item "Events", "/admin/events"
      add_item "Recurrences", "/admin/recurrences"    
      add_item "Resources", "/admin/resources"
      add_item "Event Categories", "/admin/event_categories"
      add_item "Resource Categories", "/admin/resource_categories"
    end  

    User.has_many :created_events, :class_name => 'Event', :foreign_key => 'created_by'
    User.has_many :updated_events, :class_name => 'Event', :foreign_key => 'updated_by'
    #Google::CalendarClient.instance.login('calendar@daybreakweb.com', PASSWORD) unless Google::CalendarClient.instance.token
    Google::CalendarClient.instance.token = 'REPLACE WITH TOKEN' if production
    Google::Event.extended_prop :contact_name
    Google::Event.extended_prop :contact_email
    Event.class_eval{include Googlize} if production
  end
end

