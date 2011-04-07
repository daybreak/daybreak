require File.dirname(__FILE__) + '/recurrences_controller'
require 'date'

class Admin::EventsController < ApplicationController
  before_filter :build_new_event, :only => [:new, :create]
  before_filter :set_defaults
  before_filter :get_repeat_events, :only => [:create, :update]

  only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
    :when => [:admin,:staff],
    :denied_url => {:controller => '/admin/users', :action => :bounce}

  def index
    if params[:from] or params[:thru]
      @events = Event.find_between(params[:from], params[:thru])
    elsif params[:status]
      @events = Event.find_by_status(params[:status])
    else
      @events = Event.find_recent_edits
    end
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def archive
    from, thru = 	period_for(params[:year],params[:month],params[:day])
    @events = Event.find_between(from, thru)
    @last_year = last_year
    @last_month = last_month
    @this_month = this_month
    render :action => :index
  end

  def new
  end

  def copy
		@event = Event.find(params[:id]).copy
    render :action => :new
  end

  def create
    if create_events
      notice = "Event was successfully created."
      notice += '  It was repeated on ' + @repeat_dates.map{|date| date.strftime('%m/%d/%Y')}.join(', ') + '.' if @repeat_dates.length > 1
      flash[:notice] = notice
      redirect_to :action => :edit, :id => @event.id
    else
      flash[:error] = 'Unable to save event.' + @event.errors.full_messages.join('<br/>')
      render :action => :new
    end
  end

  def edit
    @event = Event.find(params[:id])
    get_relations
  end

  def update
    params[:event][:resource_ids ] ||= [] #ensure deletes
    params[:event][:appear_on_ids] ||= [] #ensure deletes
    @event = Event.find(params[:id])
    @event.updated_by = current_user
    @recurrences = Recurrence.find_current
    status_changed = @event.status != params[:event][:status]

    if update_events
      mailing = status_changed && @event.access_key
      EventResponseMailer.deliver(EventResponseMailer.create_event_response_notice(@event)) if mailing
      notice = ["Event was successfully updated."]
      notice << 'It was repeated on ' + @repeat_dates.map{|date| date.strftime('%m/%d/%Y')}.join(', ') + '.' if @repeat_dates.length > 0
      notice << 'A response was sent to the requester.' if mailing
      flash[:notice] = notice.join('  ')
      redirect_to :action => :edit, :id => @event.id
    else
      flash[:error] = "Event was not updated."
      render :action => :edit
    end
  end

  def destroy
    if Event.find(params[:id]).destroy
      flash[:notice] = "Event deleted."
      redirect_to :action => :index
    else
      flash[:error] = "Failed to delete event."
      redirect_to :action => :edit, :id => params[:id]
    end
  end

private
  def create_events
    success = false

    events = []
    events << @event
    events << @repeat_events
    events.flatten!
    events.each do |event|
      event.created_by = current_user
      if event.save
        success = true
      else
        break
      end
    end

    success
  end

  #TODO: Could some of this be offset to the model?  Tried once but it was tricky.
  def update_events
    calendar_changed = @event.is_a?(Googlize) && @event.calendar != params[:event][:calendar]
    if calendar_changed
      ge = @event.fetch_google_event
      ge.destroy! if ge #prevents an error when updating a canceled event
      @event.google_event_id = nil
    end
    success = @event.update_attributes(params[:event])
    @event.save if calendar_changed
    @repeat_events.each{|event| event.save } if success
    success
  end

  def get_repeat_events
    mode = params['repeat']['mode'] rescue nil
    start_at = params['event']['start_at'] rescue nil
    @repeat_dates = []
    unless mode.blank? or start_at.blank?
      dt = Date.parse(Time.parse(start_at.to_s).strftime("%m/%d/%Y"))
      mode = params['repeat']['mode']
      day = params['repeat']['day']
      ordinal = params['repeat']['ordinal'].to_i
      occurrences = params['repeat']['occurrences'].to_i

      while @repeat_dates.length < occurrences
        dt = dt + 1
        case mode
        when 'Weekdays'
          @repeat_dates << dt unless [0,6].include?(dt.strftime('%w').to_i)
        when 'Daily'
          @repeat_dates << dt
        when 'Weekly'
          @repeat_dates << dt if dt.strftime('%A') == day
        when 'Monthly'
          @repeat_dates << dt if dt.ordinal_day(ordinal, day) == dt
        end
      end
    end

    @repeat_events = []
    @repeat_dates.each do |date|
      @repeat_events << Event.new(params[:event]).adjust_date(date)
    end
    @repeat_events
  end

  def set_defaults
    Event.filtered_event_categories = []
    @recurrences = Recurrence.find_current
    @categorized_resources = Resource.find(:all).group_by{|r| r.resource_category.name }
    page_ids = [*current_user.bookmarked_page_list] + [0]
    @bookmarks = Page.all(:conditions => "id IN (#{page_ids.join(',')})")
  end

  def period_for(year, month, day)
    if day
      from = Time.gm(year, month, day)
      thru = from + 1.day - 1.second
    elsif month
      from = Time.gm(year.to_i, month.to_i, 1)
      tmp = (DateTime.new(from.year, from.month, from.day) >> 1)
      thru = Time.gm(tmp.year, tmp.month, tmp.day) - 1
    else
      from = Time.gm(year.to_i, 1, 1)
      thru = Time.gm(year.to_i + 1, 1, 1) - 1
    end
    [from, thru]
  end

  def this_month
    m = DateTime.new(Time.now.year, Time.now.month, 1)
    [m.year, m.month.to_s.rjust(2,'0')]
  end

  def last_month
    m = DateTime.new(Time.now.year, Time.now.month, Time.now.day) << 1
    [m.year, m.month.to_s.rjust(2,'0')]
  end

  def last_year
    Time.now.year - 1
  end

  def build_new_event
    @event = Event.new(params[:event])
  end

  def get_relations
    @subordinate_relations = @event.subordinate_relations if @event
    @relations = {}
    @bookmarks.each do |bookmark|
      @relations[bookmark.id] = [bookmark, false]
    end
    @subordinate_relations.each do |relation|
      @relations[relation.superior_id] = [relation.superior, true]
    end if @subordinate_relations
    @relations = @relations.values.sort_by{|page,checked|page.url}
    @relations ||= []
  end
end

