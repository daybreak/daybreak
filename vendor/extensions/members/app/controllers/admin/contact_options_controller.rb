class Admin::ContactOptionsController < ApplicationController
  layout "admin", :except => :index

	verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

	before_filter :load_contact_types, :except => :destroy

  def index
    person_id = params[:person_id]
    if person_id
      @person = Person.find(person_id)
			contact_options = @person.contact_options
			contact_options.build ##
    else
			contact_options = ContactOption.find(:all)
    end
		@contact_option_pages, @contact_options = paginate_collection :collection => contact_options, :page => params[:page]
    render :layout => @person ? nil : 'admin'
  end

	def new
		@person = Person.find(params[:person_id])
		@contact_option = ContactOption.for_person(@person)
	end

  def create
   	@contact_option = ContactOption.new(params[:contact_option])
    if @contact_option.save
      flash[:notice] = 'Contact option was successfully created.'
      redirect_to :controller => 'persons', :action => :edit, :id => @contact_option.person_id
    else
      render :action => :new
    end
  end

  def edit
    @contact_option = ContactOption.find(params[:id])
  end

  def update
    @contact_option = ContactOption.find(params[:id])
    if @contact_option.update_attributes(params[:contact_option])
      flash[:notice] = 'Contact option was successfully updated.'
      redirect_to :action => :edit, :id => @contact_option
    else
      render :action => :edit
    end
  end

	def destroy
		co = ContactOption.find(params[:id])
		co.destroy
		render :text => "destroyed"
	end

private

  def load_contact_types
    @contact_types = ContactType.find(:all, :order => "name")
  end
end

