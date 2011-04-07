class Admin::RegistrationsController < ApplicationController
  only_allow_access_to :index,
    :when => [:admin,:writer,:staff],
    :denied_url => {:controller => 'admin/users', :action => :bounce}

  def index
    @event = Page.find(params[:page_id])
    @registrations = @event.registrations
    render :layout => false
  end
end

