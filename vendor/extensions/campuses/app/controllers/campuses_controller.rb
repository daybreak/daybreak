class CampusesController < ApplicationController
  no_login_required
  no_campus_required

  before_filter :forget_everything

  def login
    campus = request.path_info.chomp('/').split('/').last
    cookies['campus'] = {:value => campus, :expires => 1.year.from_now }
    referrer = request.env["HTTP_REFERER"]
    begin
      redirect_to(campus_menu(referrer) ? '/' : :back)
    rescue
      redirect_to '/'
    end
  end

  def logout
    cookies.delete 'campus'
    redirect_to :back
  rescue
    redirect_to '/'
  end

  def forget_everything
    if defined? ResponseCache == 'constant'
      ResponseCache.instance.clear
    else
      Radiant::Cache.clear
    end
  end

end

