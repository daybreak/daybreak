class Admin::GroupMembersController < ApplicationController
 only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
 	:when => [:admin,:staff,:leader],
 	:denied_url => {:controller => '/admin/users', :action => :bounce}

  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def index
  	if params[:group_id]
  		@group = Group.find(params[:group_id])
  		@group_members = @group.group_members
  	elsif params[:name_start]
	  	@people = Person.find(:all, :conditions => "last_name LIKE \"#{params[:name_start]}%\"", :order => 'last_name, first_name')
  	else
	  	@people = Person.find(:all, :order => 'last_name, first_name')
  	end
		render :layout => false
  end

  def new
    @person = Person.new
    setup_interface
  end

  def create
    @person = Person.new(params[:person])
    if @person.save
	    Person.save_contact_options(@person, params)
      flash[:notice] = 'Person was successfully created.'
      redirect_to :action => :edit, :id => @person.id
    else
      render :action => :new
    end
  end

  def edit
    @person = Person.find(params[:id])
		setup_interface
  end

  def update
    @person = Person.find(params[:id])
    if @person.update_attributes(params[:person])
      Person.save_contact_options(@person, params)
      flash[:notice] = 'Person was successfully updated.'
      redirect_to :action => :edit, :id => @person
    else
      render :action => :edit
    end
  end

  def destroy
    Person.find(params[:id]).destroy
    redirect_to :action => :index
  end
end

