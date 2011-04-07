class Admin::ContactTypesController < ApplicationController
  layout "admin"

	verify :method => :post, :only => [ :delete, :create, :update ], :redirect_to => { :action => :index }

  def index
    @contact_types = ContactType.find(:all)
  end

  def new
    @contact_type = ContactType.new
  end

  def create
    @contact_type = ContactType.new(params[:contact_type])
    if @contact_type.save
      flash[:notice] = 'Contact type was successfully created.'
      redirect_to :action => :index
    else
      render :action => :new
    end
  end

  def edit
    @contact_type = ContactType.find(params[:id])
  end

  def update
    @contact_type = ContactType.find(params[:id])
    if @contact_type.update_attributes(params[:contact_type])
      flash[:notice] = 'Contact type was successfully updated.'
      redirect_to :action => :edit, :id => @contact_type
    else
      render :action => :edit
    end
  end

  def destroy
    ContactType.find(params[:id]).destroy
		flash[:notice] = 'Contact type was successfully deleted.'
    redirect_to :action => :index
  end
end

