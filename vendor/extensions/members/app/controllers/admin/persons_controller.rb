PublicAccessExtension.activate

class Admin::PersonsController < ApplicationController
  only_allow_access_to :index, :join_group, :leave_group, :new, :edit, :add_contact_option, :update, :destroy,
    :when => [:admin,:staff],
    :denied_url => {:controller => 'admin/users', :action => :index}

  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def index
    #TODO: flash is retained one time too many after error is corrected
    begin
      render :layout => false if params[:position_id]
      @people = Person.find_by_params params
    rescue Exceptions::InsufficientCriteria => error
      @people = []
      flash[:error] = error.message
    end
  end

  def search
    if params.include?(:name_start) && params[:name_start].to_s.length > 0
      @people = Person.find(:all, :conditions => "last_name LIKE \"#{params[:name_start]}%\"", :order => 'last_name, first_name')
    else
      @people = []
    end
    if params[:group_id]
      @group = Group.find(params[:group_id])
      @subhead = "<h2>Search Results <small>(add members)</small></h2>"
      render :partial => 'admin/persons/table', :group_id => @group.id, :layout => false
    elsif params[:position_id]
      @position = Position.find(params[:position_id])
      @subhead = "<h2>Search Results <small>(add supervised people)</small></h2>"
      render :partial => 'admin/persons/table', :position_id => @position.id, :layout => false
    end
  end

  def new
    @person = Person.new
    @person.set_defaults
    setup_interface
  end

  def create
    @person = Person.new(params[:person])
    if @person.save
      Person.save_contact_options(@person, params)
      Person.save_positions(@person, params)
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

  def add_contact_option
    @contact_option = ContactOption.new
    @contact_types = ContactType.find(:all)
  end

  def add_position
    @position = Position.new
    @position_types = PositionType.find(:all)
  end

  def update
    @person = Person.find(params[:id])
    if @person.update_attributes(params[:person])
      Person.save_contact_options(@person, params)
      Person.save_positions(@person, params)
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

private
  def setup_interface
    @person.contact_options.build unless @person.contact_options.any?
    @person.positions.build unless @person.positions.any?
    @contact_types = ContactType.find(:all)
    @position_types = PositionType.find(:all)
    @contact_options = @person.contact_options
    @positions = @person.positions
  end
end

