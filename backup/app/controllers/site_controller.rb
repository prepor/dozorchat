class SiteController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  before_filter :login_required, :only => [ :edit, :update, :destroy ]
  
  

  # render new.rhtml
  def index
    if logged_in? then
      redirect_to team_path(self.current_team.id)
    end
  end
  
  def restore_pass
    
  end
  
  def restore_pass_send
    team=Team.find_by_email(params[:email])
    
    if team then
      Mailer.deliver_restore_pass(team.email,team.password_plain)
      flash[:notice]="На указаный Email выслано письмо с паролем. Проверяйте почту."
      redirect_to root_path
    else
      flash[:error]="Такого Email нет в базе."
      render :action => "restore_pass"
    end
  end

end
