class PersonsController < ApplicationController
  default_radiant_layout

	#TODO: add helpers this way -- possibly even adding to base controller -- remove empty helpers classes
	helper MarkupHelpers::Toggles

	no_login_required

	verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }
	before_filter :check_permission, :only => [:index, :show]
	before_filter :fetch_person
	before_filter :find_people, :only => :index
	before_filter :set_title

	def index
		render :layout => params[:position_id].blank?, :action => :index
	end

	def new
		@content_for_title = "New Directory Entry"
		@person = Person.new
		@person.set_defaults
		setup_interface
	end

	def show
		@person = Person.find(params[:id])
		unless @person.share_info_with(current_user)
			flash[:notice] = "That directory entry is not viewable."
			redirect_to :back
		end
		@content_for_title = @person.full_name
	end

	def not_me
		if current_user
			current_user.reject_identity!
			redirect_to :controller => '/users', :action => :edit
		else
			redirect_to :action => :index
		end
	end

	def create
		@person = Person.new(params[:person])
		@content_for_title = "Directory Entry"
		if @person.save
			current_user.person ||= @person
			current_user.save!
			Person.save_contact_options(@person, params)
			flash[:notice] = 'Directory entry was successfully created.'
			redirect_to :action => :edit, :id => @person.id
		end
	end

	def edit
		#redirect_to :action => 'edit', :id => nil if params[:id] #drop id if present
		if @person = current_user.person
			setup_interface
			if request.post?
				if @person.update_attributes(params[:person])
					Person.save_contact_options(@person, params)
					flash[:notice] = 'Directory entry was successfully updated.'
				 	redirect_to(:action => 'edit') and return
				end
			end
			@content_for_title = @person.full_name
		end
	end

	def add_contact_option
		@contact_option = ContactOption.new
		@contact_types = ContactType.find(:all)
	end

	def destroy
		Person.find(params[:id]).destroy
		redirect_to :action => :index
	end

	def overview
		@people = Person.find_latest_additions()
	end

private
	def find_people
		@people = Person.find_by_params(params).select{|person| person.share_info_with(current_user)}
	end

	def setup_interface
		@person.contact_options.build unless @person.contact_options.any? or request.post?
		@contact_types = ContactType.find(:all)
		@contact_options = @person.contact_options
	end

	def fetch_person
		@person = Person.find(:first) || Person.new
	end

	def set_title
		@content_for_title = "Daybreak Membership Directory"
	end

	def check_permission
		notice = nil
		if !current_user
			notice = 'Please login before attempting to access that area.'
		elsif !current_user.admin?
			case current_user.status
			when :unregistered:
				notice = 'We are unable to validate a membership in our records having the email address with which you registered.  The best course is to contact the church office for assistance.'
			when :registered:
				notice = 'Our directory is restricted to members only.'
      end
    end
		if notice
			flash[:notice] = notice
			redirect_to :controller => '/users', :action => 'edit'
    end
		notice.nil?
  end
end

