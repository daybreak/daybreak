class UsersController < ApplicationController
  default_radiant_layout
  no_login_required
  before_filter :find_user, :except => [:unlock, :register, :logout]
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => '/'

  def login
    if request.post?
      username = params[:username]
      password = params[:password]
      user = User.authenticate(username, password)
      if !user
        flash[:notice] = "Username/password combination failed."
      elsif user.unlocked?
        self.current_user = user
        #ResponseCache.instance.clear -- doesn't work (see note below)
        cookies['username'] = {:value => username, :expires => 10.days.from_now}
        if user.attach_person!
          flash[:notice] = "We believe we have you in our database.  Please check your information."
          redirect_to :controller => "family/persons", :action => "edit" and return
        else
          goto_default_page and return
        end
      else
        send_activation(user)
        flash[:notice] = "Your account requires activation before use.  An email was sent to #{user.email}."
      end
    end
    @content_for_title = "Login"
    render :action => :login
  rescue StandardError => e
    flash[:notice] = e
  end

  alias :index :login

  def logout
    self.current_user = nil
    flash[:notice] = "Logout successful.  <a href='/'>Return to home page.</a>"
    #ResponseCache.instance.clear -- this doesn't work because multiple users are accessing the site simulataneously
    redirect_to :action => "login"
  end

  def tell
    redirect_to '/' unless flash.any?
  end

  def debug
    radiant_render :layout => 'Edgy'
  end

  def change_password
    if request.post? && @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      flash[:notice] = "Password changed."
      redirect_to '/users'
    end
    @content_for_title = "Change Password"
  end

  def edit

    if @user
      if request.post?
        set_password = params[:password]
        password_confirmed = set_password && params[:password] == params[:password_confirmation]
        password_changed = false

        if !set_password
        elsif password_confirmed
          @user.password = params[:password]
          password_changed = true
        else
          flash[:notice] = "Password confirmation did not match password."
        end

        email_changed = @user.email != params[:email] if params[:email]

        if @user.update_attributes(params[:user])
          if email_changed # this requires the new email to be confirmed.
            @user.lock!
            send_activation(@user)
          end

          flash[:notice] = password_changed ? 'Password was successfully updated.' : 'User was successfully updated.'
        end
      end
      @content_for_title = "Edit User"
    else
      redirect_to :action => 'login'
    end
  end

  def unlock
    @user = User.find(params[:id])
    if @user
      if @user.unlocked?
        flash[:notice] = "Your account was already active."
        redirect_to :action => 'login'
      elsif @user.locking_key == params[:key]
        if @user.unlock!
          @user.attach_person!
          self.current_user = @user
          flash[:notice] = "Your account has been activated."
          #redirect_to :action => :edit
        else
          flash[:notice] = "Your account was not activated."
        end
      end
    end
  end

  def register
    @user = User.new(params[:user])
    @content_for_title = "Member Registration"
    if request.post?
      if @user.lock!
        send_activation(@user)
        @content_for_title = "Registered! (one more thing to do)"
      else
        flash[:notice] = "Registration failed."
      end
    end
  end

  def last_logins
    @users = User.all
  end

private

  def send_activation(user)
    email = ActivationMailer.create_activation(user)
    ActivationMailer.deliver(email)
  end

  def find_user
    @user = self.current_user
  end

  def goto_default_page
    redirect_to self.current_user.landing_page
  end
end

