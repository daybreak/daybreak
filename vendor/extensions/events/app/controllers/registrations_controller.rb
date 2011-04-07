class RegistrationsController < ApplicationController
  no_login_required
  default_radiant_layout
  before_filter :set_title
  before_filter :set_event, :only => [:new, :attendance, :create]
  before_filter :set_registration, :only => [:edit, :update, :confirmation]
  before_filter :prevent_unauthorized_access, :only => :edit

  def new
    @registration = @event.registrations.build
    raise 'Failed to identify the event with the page_id parameter.' unless @event
  end

  def edit
  end

  def attendance
    @registrations = @event.registrations.select{|registration| registration.registrants > 0}
  end

  def confirmation
    @content_for_title = 'Confirm Registration'
    if !@registration.password.blank? and @registration.password != params[:p] #TODO: test for admin or authorized user
      flash[:warning] = "You are not permitted to access/update that registration."
      redirect_to :controller => 'recurrences'
    end
  end

  def update
    if @registration.update_attributes(params[:registration])
      message = ['Registration was updated.']
      message << 'You are no longer planning on attending.' if @registration.withdrawn?
      flash[:notice] = message.join('  ')
    else
      flash[:notice] = format_errors(@registration.errors, 'Registration was not updated.')
    end
    goto_edit
  end

  def create
    @registration = @event.registrations.build(params[:registration])
    @registration.password = random_password
    if @registration.save
      message	= ["Registration complete!  Please note your confirmation number: <strong>#{@registration.id}</strong>"]
      unless @registration.contact_email.blank?
        begin
          RegistrationMailer.deliver_registration(@registration)
          message << "You will receive an email shortly."
        rescue
          message << "Please bookmark this page in case you need to update your registration."
        end
      end
      flash[:notice] = message.join("<br />")
      goto_edit
    else
      flash[:error] = format_errors(@registration.errors, 'Registration failed.  Please correct the errors and resubmit.')
      redirect_to :action => :new, :page_id => @registration.page.id
    end
  end

private
	def format_errors(errors, header = nil) #TODO: move to application controller
		markup = []
		markup << header if header
		unless errors.full_messages.empty?
			markup << '<ul>'
			errors.full_messages.each do |message|
				markup << "<li>#{message}</li>"
			end
			markup << '</ul>'
		end
		markup.join("\n")
	end
	
  def set_event
    #@event = Event.first(:conditions => "event_id = #{params[:event_id]}") if params[:event_id]
    @event = Event.find(params[:page_id]) if params[:page_id]
    @recurrence = @event.recurrence if @event
    puts "Set event #{@event.id}" if @event    
  end

  def set_registration
    @registration = Registration.find(params[:id])
    @event = @registration.page
    @recurrence = @event.recurrence if @event
  end

  def prevent_unauthorized_access
    unless allow = current_user && (current_user.admin? || @registration.created_by == current_user)
      flash[:notice] = "Cannot edit that registration"
      redirect_to '/'
    end
  end

  def set_title
    @content_for_title = "Registration"
  end

  def goto_edit
    if is_user
      redirect_to :action => :edit, :id => @registration
    else
      redirect_to :action => :confirmation, :id => @registration, :params => {:p => @registration.password}
    end
  end

  def random_password( len = 10 )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def is_user
    current_user != nil
  end
end

