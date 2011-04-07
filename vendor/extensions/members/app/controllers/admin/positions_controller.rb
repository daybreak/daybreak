class Admin::PositionsController < ApplicationController
  only_allow_access_to :index, :search, :join_group, :leave_group, :new, :edit, :add_contact_option, :update, :destroy,
    :when => [:admin,:staff],
    :denied_url => {:controller => '/admin/users', :action => :preferences}

  def index
    if params[:position_type_id]
      @position_types = PositionType.find(params[:position_type_id])
    else
      @position_types = PositionType.find(:all)
    end
  end

  def new
    @person = Person.find(params[:person_id])
    @positions = Position.for_person(@person)
  end

  def create
    @positions = Position.new(params[:positions])
    if @positions.save
      flash[:notice] = 'Position was successfully created.'
      redirect_to :controller => 'persons', :action => :edit, :id => @position.person_id
    else
      render :action => :new
    end
  end

  def edit
    @position = Position.find(params[:id])
    @people = @position.subordinates.collect{|subordinate| subordinate.person }
  end

  def update
    @position = Position.find(params[:id])
    if @position.update_attributes(params[:position])
      flash[:notice] = 'Position was successfully updated.'
      redirect_to :action => :edit, :id => @position
    else
      render :action => :edit
    end
  end

  def add_subordinate
    @position = Position.find(params[:id])
    @person = Person.find(params[:person_id])
    @group_member = @position.add_subordinate(@person)
    @people = @position.people
    render :partial => '/admin/persons/table'
  end

  def remove_subordinate
    @position = Position.find(params[:id])
    @person = Person.find(params[:person_id])
    @subordinate = @position.remove_subordinate(@person)
    @people = @position.people
    render :partial => '/admin/persons/table'
  end

  def destroy
    p = Position.find(params[:id])
    person = p.person
    p.destroy
    redirect_to :controller => "persons", :action => :edit, :id => person.id
  end
end

