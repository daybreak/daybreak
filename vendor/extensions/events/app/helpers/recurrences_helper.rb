module RecurrencesHelper
 	include MarkupHelpers::Toggles
	include MarkupHelpers::AuthenticityToken
	include MarkupHelpers::Radiant
    	
  def calbox(event) #TODO: try converting this to a partial
    include_stylesheet 'calbox'

    markaby do
      div.calbox do
        div(:class=> "calheader#{event.taking_registrations? ? '' : ' calclosed'}") do
          span.calday{event.start_at.strftime('%a, %b %e')}
          br
          span.caltime{time_period(event.start_at, event.end_at)}
          if event.continuing_events.length > 0
            br
            text "(#{event.continuing_events.length + 1} sessions)"
          end
        end
        if event.subtitle
          b{event.subtitle}
          br
        end
        text link_to("#{event.num_adults} Adults", :controller => 'registrations', :action => 'attendance', :page_id => event)
        br
        text link_to("#{event.num_children} Children", :controller => 'registrations', :action => 'attendance', :page_id => event)
        br
        text "#{event.describe_space}"
        br
        if event.taking_registrations?
          text link_to("register", :controller => 'registrations', :action => 'new', :page_id => event)
        else
          text "closed"
        end
      end
    end
  end

  def new_recurrence_image_tag
    image_tag('/images/admin/new-recurrence.png', :alt => 'New Recurrence')
  end
end

