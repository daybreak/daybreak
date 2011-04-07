class MessagesController < ApplicationController
	default_radiant_layout
	no_login_required
	# GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
	verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

	#TODO: test xml
	def index
		respond_to do |format|
			format.html do
				@series = Series.find(params[:series_id]) if params[:series_id]
				since = params[:since]
				if @series
					@empty_series = []
					@empty_series << @series if @series.num_messages == 0
					@messages = @series.messages.reverse
				elsif since
					date = Date.strptime(since, '%m/%d/%Y')
					@empty_series = []
					@messages = Message.find_since(date)
				else
					@empty_series = Series.find_empty || []
					@messages = Message.find_since
				end
				@content_for_title = "Messages"
      end
			format.xml do
				feed
      end
    end
	end

	def feed
		render :xml => Message.rss
	end

	def show
		@message = Message.find(params[:id])
		@content_for_title = @message.title
	end
end

