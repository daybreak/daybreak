class Admin::ConfigurationController < ApplicationController

  only_allow_access_to :index, :when => :admin,
    :denied_url => {:controller => 'admin/users', :action => 'bounce'}

  def index
    if request.post?
      params[:config].each do |key, value|
        Radiant::Config[key] = value
      end
    end

    @config_items = Radiant::Config.find(:all)
  end

end

