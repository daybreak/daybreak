class Admin::GroupMeetingsController < ApplicationController
  only_allow_access_to :index, :index, :new, :create, :edit, :update, :destroy,
  	:when => [:admin,:staff,:leader],
  	:denied_url => {:controller => 'admin/users', :action => :preferences}

	def index
		@group = Group.find(params[:group_id])
		@group_meetings = @group.group_meetings
		render :layout => false
	end

	def new
		@group = Group.find(params[:group_id])
		@group_meeting = GroupMeeting.new
		@group_meeting.date = Date.today
		@group_meeting.group = @group
	end

	def create
		@group = Group.find(params[:group_id])
    @group_meeting = GroupMeeting.new(params[:group_meeting])
    @group_meeting.created_by = current_user
    @group_meeting.group = @group
    set_attendees @group_meeting
    if @group_meeting.save
      flash[:notice] = 'Meeting was successfully created.'
      back_to @group
    else
      render :action => :new
    end
	end

	def edit
		@group_meeting = GroupMeeting.find(params[:id])
		@group = @group_meeting.group
	end

	def update
		@group_meeting = GroupMeeting.find(params[:id])
		@group_meeting.updated_by = current_user
		@group = @group_meeting.group
		set_attendees @group_meeting
    if @group_meeting.update_attributes(params[:group_meeting])
      flash[:notice] = 'Meeting was successfully updated.'
      back_to @group
    else
      render :action => :new
    end
	end

	def destroy
		GroupMeeting.find(params[:id]).destroy
    redirect_to :controller => 'groups', :action => :index
	end

private
	def back_to(group)
		redirect_to :controller => 'groups', :action => :edit, :id => group, :tab => "meetings"
	end

	def set_attendees(meeting)
		@people = get_attendees
    meeting.people = @people
	end

	def get_attendees
		attendees = params[:attendance].collect{ |attendee| attendee[0] }
		Person.find(attendees)
	end
end

