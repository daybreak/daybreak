class CampusesExtension < Radiant::Extension
  version "1.0"
  description "Tracks the campus the user most recently selected"
  url ""

  CAMPUSES = ['gp', 'cp']
  NON_CAMPUS_URLS = ['/new-here']
  MENU = '/campuses'

  define_routes do |map|
    CAMPUSES.each do |campus|
      map.campus "#{campus}", :controller => 'campuses', :action => 'login'
      map.campus "campus/login/#{campus}", :controller => 'campuses', :action => 'login'
    end
    map.campus "campus/logout", :controller => 'campuses', :action => 'logout'
  end

  def activate
    ApplicationController.send :include, Campuses::ForceSelection
    Page.send :include, Campuses::Tags
    CampusPage
  end
end

