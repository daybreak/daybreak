class Family::EventsController < ApplicationController
	default_radiant_layout
	no_login_required

  before_filter :set_defaults
  after_filter :set_title

	def event_request
		id = params[:id]
		access_key = params[:access_key]
		@event = id && access_key ? Event.find(id) : Event.new(:event_status => 'pending', :created_by => current_user, :event_category_id => 3)
    @categorized_resources = Resource.find(:all).group_by{|r| r.resource_category.name }
    if id && !access_key #prevent access to non-requested events
    	redirect_to :controller => 'family/events', :action => :event_request, :id => nil
    elsif !@event.new_record? && @event.access_key != access_key
    	flash[:error] = "Permission denied"
    	redirect_to '/'
		elsif request.post?
			unless @event.pending?
				flash[:error] = "This event has already been reviewed and cannot be changed."
			else
				@event.updated_by = current_user
			  params[:event][:resource_ids] ||= [] #ensure deletes
				if @event.update_attributes(params[:event].merge(:access_key => @event.access_key || Page.generate_key))
				  begin
  					EventRequestMailer.deliver(EventRequestMailer.create_event_request_notice(@event))
	  				flash[:notice] = "You can expect your request to be reviewed within a couple business days.  You will receive an email shortly."
					rescue
  					flash[:notice] = "You can expect a reply to your request within a couple business days.  Please bookmark this page in case you need to review or adjust it later."
					end
					redirect_to :id => @event.id, :access_key => @event.access_key
				else
					flash[:error] = "Unable to save event request\n" + @event.errors.full_messages.join("\n")
				end
			end
		end
	end

	def invite
		@event = Event.find(params[:id])
	end

  def index
		@events = Event.find_since
  end

	def show
		@event = Event.find(params[:id])
	end

private

  def set_defaults
    Event.filtered_event_categories = [1,2,3,4]
  end

  def set_title
    @content_for_title = @event ? @event.title : 'Events'
  end
end

