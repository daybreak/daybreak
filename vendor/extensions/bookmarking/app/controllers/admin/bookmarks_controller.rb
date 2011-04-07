class Admin::BookmarksController < ApplicationController
  def page
    p = Page.find(params[:id])
    method = params['_method']
    if method == 'put'
      current_user.bookmark p
    elsif method == 'delete'
      current_user.unbookmark p
    end
    render :nothing => true
  end
end

