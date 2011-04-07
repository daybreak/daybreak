class EventsController < ApplicationController
	default_radiant_layout
	no_login_required

  before_filter :set_defaults
  after_filter :set_title

	def invite
		@event = Event.find(params[:id])
	end

  def index
		@events = Event.find_since
  end

	def show
		@event = Event.find(params[:id])
		render :layout => false if params[:component]
	end

private

  def set_defaults
    Event.filtered_event_categories = [1]
  end

  def set_title
    @content_for_title = @event ? @event.title : 'Events'
  end
end

