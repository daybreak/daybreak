class Admin::ResourceCategoriesController < ApplicationController
  only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
    :when => [:admin],
    :denied_url => {:controller => '/admin/users', :action => 'bounce'}

  def index
    @resource_categories = ResourceCategory.find(:all)
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def new
    @resource_category = ResourceCategory.new
  end

  def create
    @resource_category = ResourceCategory.new(params[:resource_category])
    @resource_category.created_by = current_user
    if @resource_category.save
      flash[:notice] = 'Resource Category was successfully created.'
      redirect_to :action => :edit, :id => @resource_category
    else
      flash[:error] = 'Unable to save Resource Category.'
      render :action => :new
    end
  end

  def edit
    @resource_category = ResourceCategory.find(params[:id])
  end

  def update
    @resource_category = ResourceCategory.find(params[:id])
    @resource_category.updated_by = current_user
    if @resource_category.update_attributes(params[:resource_category])
      flash[:notice] = 'Resource Category was successfully updated.'
      redirect_to :action => :edit, :id => @resource_category
    else
      flash[:error] = 'Unable to save Resource Category.'
      render :action => :edit
    end
  end

  def destroy
    ResourceCategory.find(params[:id]).destroy
    redirect_to :action => :index
  end
end

