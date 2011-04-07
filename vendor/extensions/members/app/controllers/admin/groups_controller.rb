class Admin::GroupsController < ApplicationController
  before_filter :load_group, :except => [:new, :index, :create]
  only_allow_access_to :index, :new, :create, :edit, :update, :add_member, :remove_member, :destroy,
    :when => [:admin,:staff,:leader],
    :denied_url => {:controller => '/admin/users', :action => :bounce}

  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def index
    @groups = Group.find(:all)
    @groups = @groups.select{|group| group.may_change(current_user)}
  end

  def load_group
    if params[:id]
      @group = Group.find(params[:id])
      redirect_to :controller => '/admin/users', :action => :bounce unless @group.may_change(current_user)
    end
  end

  def new
    @group = Group.new
    @group.active = :true
    #setup_interface
  end

  def create
    @group = Group.new(params[:group])
    @group.created_by = current_user
    if @group.save
      #Group.save_contact_options(@group, params)
      flash[:notice] = 'Group was successfully created.'
      redirect_to :action => :edit, :id => @group.id
    else
      render :action => :new
    end
  end

  def edit
    @people = @group.people
    @group_members = @group.group_members
    @group_meetings = @group.group_meetings
  end

  def update
    @group = Group.find(params[:id])
    redirect_to :controller => '/admin/users', :action => :bounce unless @group.may_change(current_user)
    @group.updated_by = current_user
    if @group.update_attributes(params[:group])
      if params[:group_member]
        params[:group_member].each do |index, group_member|
          GroupMember.find(group_member[:id]).update_attributes(group_member)
        end
      end

      flash[:notice] = 'Group was successfully updated.'
      redirect_to :action => :edit, :id => @group
    else
      render :action => :edit
    end
  end

  def full
    render :layout => false
  end

  def add_member
    begin
      @person = Person.find(params[:person_id])
      @group_member = @group.add_member(@person)
      @people = @group.people
      render_component :controller => 'admin/group_members', :action => 'index', :params => {:group_id => @group.id}
    rescue
      redirect_to :action => :full
    end
  end

  def remove_member
    @person = Person.find(params[:person_id])
    @group_member = @group.remove_member(@person)
    @people = @group.people
    render_component :controller => 'admin/group_members', :action => 'index', :params => {:group_id => @group.id}
  end

  def destroy
    @group = Group.find(params[:id])
    redirect_to :controller => '/admin/users', :action => :bounce unless @group.may_change(current_user)
    Group.find(params[:id]).destroy
    redirect_to :action => :index
  end

private

  def setup_interface
    @group.contact_options.build unless @group.contact_options.any?
    @contact_types = ContactType.find(:all)
    @contact_options = @group.contact_options
  end
end

