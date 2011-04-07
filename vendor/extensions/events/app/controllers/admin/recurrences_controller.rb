class Admin::RecurrencesController < ApplicationController
  def index
    @recurrences = Recurrence.find(:all, :order=> 'recurrence_category_id, sort_order, name')
    render :action => 'index'
  end

  only_allow_access_to :index, :new, :create, :update, :destroy,
    :when => [:admin,:writer,:staff],
    :denied_url => {:controller => '/admin/users', :action => :bounce}

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def new
    @recurrence = Recurrence.new
  end

  def create
    @recurrence = Recurrence.new(params[:recurrence])
    @recurrence.created_by = current_user
    if @recurrence.save
      flash[:notice] = 'Recurrence was successfully created.'
      redirect_to :action => :edit, :id => @recurrence
    else
      render :action => :new
    end
  end

  def edit
    @recurrence = Recurrence.find(params[:id])
  end

  def update
    @recurrence = Recurrence.find(params[:id])
    @recurrence.updated_by = current_user
    if @recurrence.update_attributes(params[:recurrence])
      flash[:notice] = 'Recurrence was successfully updated.'
      redirect_to :action => :edit, :id => @recurrence
    else
      render :action => :edit
    end
  end

  def destroy
    Recurrence.find(params[:id]).destroy
    redirect_to :action => :index
  end
end

