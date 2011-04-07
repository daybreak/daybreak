class GroupsController < ApplicationController
  no_login_required
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  before_filter :set_title
  before_filter :find_groups, :only => [:index, :filter]
  before_filter :find_group , :only => [:show, :join, :destroy]
  default_radiant_layout

  def index
  end

  def join
    if !current_user.person
      flash[:notice] = "You must create a person record before you can join a small group."
      redirect_to(:controller => '/family/persons', :action => :edit) and return
    elsif @group.is_full?
      flash[:notice] = 'This group is already at capacity.'
    elsif @group.belong_to?(current_user)
      flash[:notice] = "You are already in the group."
    elsif current_user.person && current_user.person.contact_options.empty?
      flash[:notice] = "You cannot join a small group until you have entered <a href='/directory/edit'>your contact information</a>."
    else
      @group_member = @group.belong_to?(current_user) || @group.add_member(@person) if @person
      send_enrollment_notice(@group_member)
      @group_member.group_role_id = 3 #Prospective Member
      @group_member.save
      flash[:notice] = "Welcome to the group.<br/>The leader has been notified and will be contacting you about your first visit."
    end
    redirect_to :action => :show, :id => @group.id
  end

  def filter
    render :partial => 'groups', :layout => false
  end

  def show
    @group_members = @group.group_members
  end

  def destroy
    @group.destroy
    redirect_to :action => :index
  end

private

  def set_title
    @content_for_title = "Small Groups"
    include_stylesheet 'groups'
  end

  def find_group
    @group = Group.find(params[:id])
    @group = nil unless @group.active
    @person = current_user.person rescue nil
    true
  end

  def find_groups
    @groups = Group.find_with(params)
    true
  end

  def send_enrollment_notice(membership)
    send = membership.group.enrollment_notice_emails.any?
    if send
      email = EnrollmentMailer.create_enrollment_notice(membership.person, membership.group)
      EnrollmentMailer.deliver(email)
    end
  end
end

