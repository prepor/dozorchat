class TeamsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  before_filter :login_required, :only => [ :edit, :update, :destroy ]
  layout false
  def show

    #debugger
    @team=self.current_team
    render :layout => "main"
  end
  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @team = Team.new(params[:team])
    @team.password_plain=params[:team][:password]
    if @team.save
      self.current_team = @team
      #redirect_back_or_default('/')
      flash[:notice] = "Cпасибо за регистрацию!"
      render :update do |page| 
        page.redirect_to team_path(@team.id) 
      end
    end
  end
  
  def edit
    @team=self.current_team
    render :layout => "main"
  end
  
  def update
    @team = self.current_team
    @team.update_attributes(params[:team])
    if @team.save
      redirect_to team_path(@team.id)
      flash[:notice] = "Изменения сохранены"
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    self.current_team.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    @current_team.destroy
    redirect_to root_path
    flash[:notice] = "Команда удалена"
  end
  
  def new_password_for_game
    self.current_team.password_for_game=params[:new_pass]
    self.current_team.save
    Crew.destroy_all :team_id => self.current_team.id
    ChatUser.destroy_all :team_id => self.current_team.id
    render :update do |page| 
      page.replace_html("password_for_game", params[:new_pass]) 
      page.replace_html("status", "Новый пароль назначен") 
    end
  end

end
