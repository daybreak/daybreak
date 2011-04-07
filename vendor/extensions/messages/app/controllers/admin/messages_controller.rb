class Admin::MessagesController < ApplicationController
  only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
    :when => [:admin,:writer,:staff],
    :denied_url => {:controller => '/admin/users', :action => 'bounce'}

  def index
    @series = Series.find(params[:series_id]) if params[:series_id]
    from = params[:from]
    if @series
      @empty_series = []
      @empty_series << @series if @series.num_messages == 0
      @messages = @series.messages.reverse
    elsif from
      date = Date.strptime(from, '%m/%d/%Y')
      @empty_series = []
      @messages = Message.find_since(date)
    else
      @empty_series = Series.find_empty || []
      @messages = Message.find_since
    end
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def new
    @message = Message.new
    if params[:series_id]
      @message.series = Series.find(params[:series_id])
    end
  end

  def create
    @message = Message.new(params[:message])
    @series = @message.series
    if @message.save
      flash[:notice] = 'Message was successfully created.'
      after_save
    else
      flash[:error] = 'Unable to save message.'
      render :action => :new
    end
  end

  def edit
    @message = Message.find(params[:id])
    @series = @message.series
  end

  def update
    @message = Message.find(params[:id])
    @series = @message.series    
    if @message.update_attributes(params[:message])
      flash[:notice] = 'Message was successfully updated.'
      after_save
    else
      flash[:error] = 'Unable to save message.'
      render :action => :edit
    end
  end

  def destroy
    Message.find(params[:id]).destroy
    redirect_to :action => :index
  end

private

  def after_save
    if @message.series
      redirect_to :action => :index, :series_id => @message.series.id
    else
      redirect_to :action => :edit, :id => @message
    end
  end
end

