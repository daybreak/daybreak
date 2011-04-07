class Admin::SeriesController < ApplicationController
  only_allow_access_to :index, :new, :create, :edit, :update, :destroy,
    :when => [:admin,:writer,:staff],
    :denied_url => {:controller => '/admin/users', :action => :bounce}

  def index
    @series = Series.paginate :page => params[:page], :per_page => 10, :order => 'created_at DESC'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  def new
    @series = Series.new
  end

  def create
    @series = Series.new(params[:series])
    if @series.save
      flash[:notice] = 'Series was successfully created.'
      redirect_to :controller => 'messages', :action => :index, :series_id => @series
    else
      flash[:error] = 'Unable to save series.'
      render :action => :new
    end
  end

  def edit
    @series = Series.find(params[:id])
  end

  def update
    @series = Series.find(params[:id])
    if @series.update_attributes(params[:series])
      flash[:notice] = 'Series was successfully updated.'
      redirect_to :controller => 'messages', :action => :index, :series_id => @series
    else
      flash[:error] = 'Unable to save series.'
      render :action => :edit
    end
  end

  def destroy
    Series.find(params[:id]).destroy
    redirect_to :controller => 'messages', :action => :index
  end
end

