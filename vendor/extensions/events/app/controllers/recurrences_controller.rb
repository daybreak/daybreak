class RecurrencesController < ApplicationController
	no_login_required
	before_filter :find_recurrences, :only => [:catalog, :index]
	default_radiant_layout
	verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

	def index
	end

	def catalog
		render :action => :index
	end

	def about
		@recurrence = Recurrence.find(params[:id])
		@content_for_title = "About #{@recurrence.name}"
	end

private

	def find_recurrences
		@recurrences = Recurrence.find_current
		@recurrences = @recurrences.select{|recurrence| recurrence.find_upcoming_events.any? } unless params[:action] == 'catalog'
		@recurrences = @recurrences.select{|recurrence| recurrence.recurrence_category.slug == slug} if slug
		@content_for_title = slug ? RecurrenceCategory.find(:first, :conditions => ["slug = ?", slug]).name.pluralize : "Programs"
	end

	def slug
		params[:slug]
	end
end

