class Admin::ResourcesController < ApplicationController
  only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
    :when => [:admin],
    :denied_url => {:controller => '/admin/users', :action => :bounce}

  def index
    @resources = Resource.find(:all)
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def new
    @resource = Resource.new
  end

  def create
    @resource = Resource.new(params[:resource])
    @resource.created_by = current_user
    if @resource.save
      flash[:notice] = 'Resource was successfully created.'
      redirect_to :action => :edit, :id => @resource
    else
      flash[:error] = 'Unable to save Resource.'
      render :action => :new
    end
  end

  def edit
    @resource = Resource.find(params[:id])
  end

  def update
    @resource = Resource.find(params[:id])
    @resource.updated_by = current_user
    if @resource.update_attributes(params[:resource])
      flash[:notice] = 'Resource was successfully updated.'
      redirect_to :action => :edit, :id => @resource
    else
      flash[:error] = 'Unable to save Resource.'
      render :action => :edit
    end
  end

  def destroy
    Resource.find(params[:id]).destroy
    redirect_to :action => :index
  end
end

