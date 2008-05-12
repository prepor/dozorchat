# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  

  # render new.rhtml
  def new
  end

  def create
    self.current_team = Team.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_team.remember_me
        cookies[:auth_token] = { :value => self.current_team.remember_token , :expires => self.current_team.remember_token_expires_at }
      end

      flash[:notice] = "Вы вошли."
      render :update do |page| 
        page.redirect_to team_path(self.current_team.id) 
      end
    else
      render :text => '<h2 align="center">Неаправильный логин или пароль</h2>'
    end
  end

  def destroy
    self.current_team.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "Вы вышли."
    redirect_back_or_default('/')
  end
end
