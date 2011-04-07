class Admin::EventCategoriesController < ApplicationController
  only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
    :when => [:admin],
    :denied_url => {:controller => '/admin/users', :action => :bounce}

  def index
    @event_categories = EventCategory.find(:all)
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def new
    @event_category = EventCategory.new
  end

  def create
    @event_category = EventCategory.new(params[:event_category])
    @event_category.created_by = current_user #TODO use Radiant's Change observer?
    if @event_category.save
      flash[:notice] = 'Event Category was successfully created.'
      redirect_to :action => :edit, :id => @event_category
    else
      flash[:error] = 'Unable to save Event Category.'
      render :action => :new
    end
  end

  def edit
    @event_category = EventCategory.find(params[:id])
  end

  def update
    @event_category = EventCategory.find(params[:id])
    @event_category.updated_by = current_user
    if @event_category.update_attributes(params[:event_category])
      flash[:notice] = 'Event Category was successfully updated.'
      redirect_to :action => :edit, :id => @event_category
    else
      flash[:error] = 'Unable to save Event Category.'
      render :action => :edit
    end
  end

  def destroy
    EventCategory.find(params[:id]).destroy
    redirect_to :action => :index
  end
end

