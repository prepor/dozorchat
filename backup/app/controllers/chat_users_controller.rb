class ChatUsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  before_filter :chat_logined, :only => [:update, :destroy, :update_name, :update_crew, :create_crew, :get_caption, :activity]

  # render new.rhtml
  def new
    @team=Team.find(params[:team_id])
  end
  def check_pass
    #debugger
    @chat_user=ChatUser.new
    chat_user_env params[:team_id]
    
  end

  def create
    @chat_user = ChatUser.new(params[:chat_user])
    @chat_user.last_activity = Time.now.to_s(:db)
    chat_user_env @chat_user.team_id
    if Team.find(:first,:conditions => {'id' => @chat_user.team_id, 'password_for_game' => params[:password_for_game]})
      if !params[:crew_title].empty? and @chat_user.crew_id.nil? then
        crew=Crew.new
        crew.team_id=@chat_user.team_id
        crew.title=params[:crew_title]
        crew.save
        @chat_user.crew=crew
      end
      if @chat_user.save
        session[:chat_user] = @chat_user
        flash[:notice] = "Добро пожаловать, мой друг!"
        @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
        render :juggernaut => {:type => :send_to_channels, :channels => ['team_' + @chat_user.team.id.to_s]} do |page|
            page.replace_html "change_crew_div_list", :partial => "chat/change_crew_div_list"
            page.replace_html "crews_list", :partial => "chat/crews_list"
            page.visual_effect "highlight", "crews_list"
        end
        redirect_to :controller => "chat", :action => "show", :team_id => params[:team_id]
        
      else
        flash[:error] = "Что-то пошло не так..."
        render :action => 'new'
      end
    else
      flash[:error] = "Пароль не подходит"
      render :action => 'new'
    end
    
  end
  
  def update_name
    @chat_user.name=params[:name]
    @chat_user.save
      # render :update do |page|
      #   page.replace_html "bar_errors", "Имя изменено"
      # end 
    
    jugg_execute
    render :nothing => true
  end
  
  def update_crew
    crew=@chat_user.crew
    @chat_user.crew_id=params[:crew_id]
    @chat_user.save
    if crew.chat_users.length < 1 then
      crew.destroy
    end
    # render :update do |page|
    #   page.replace_html "bar_errors", "Экипаж изменен"
    # end
    jugg_execute
    render :nothing => true
  end
  
  def create_crew
    new_crew= Crew.new
    new_crew.title=params[:title]
    new_crew.team=@chat_user.team
    new_crew.save
    crew=@chat_user.crew
    @chat_user.crew=new_crew
    @chat_user.save
    if crew.chat_users.length < 1 then
      crew.destroy
    end
    # render :update do |page|
    #   page.replace_html "bar_errors", "Экипаж изменен"
    # end
    jugg_execute
    render :nothing => true
  end
  
  def jugg_execute
    @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
    
    render :juggernaut => {:type => :send_to_channels, :channels => ['team_' + @chat_user.team.id.to_s]} do |page|
        page.replace_html "change_crew_div_list", :partial => "chat/change_crew_div_list"
        page.replace_html "form_message_caption", "#{@chat_user.crew.title} [#{@chat_user.name}]"
        page.replace_html "crews_list", :partial => "chat/crews_list"
        page.visual_effect "highlight", "crews_list"
    end
  end
  
  def get_caption
    render :update do |page|
      page.replace_html "form_message_caption", "#{@chat_user.crew.title} [#{@chat_user.name}]"
    end
  end
  
  def destroy
    
    @chat_user.destroy
    if @chat_user.crew.chat_users.length < 1 then
      @chat_user.crew.destroy
    end
    flash[:notice] = "Вы вышли из чата!"
    @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
    render :juggernaut => {:type => :send_to_channels, :channels => ['team_' + @chat_user.team.id.to_s]} do |page|
        page.replace_html "change_crew_div_list", :partial => "chat/change_crew_div_list"
        page.replace_html "crews_list", :partial => "chat/crews_list"
        page.visual_effect "highlight", "crews_list"
    end
    redirect_to :controller => "chat", :action => "show", :team_id => @chat_user.team_id
    
  end
  
  def activity
    @chat_user.last_activity=Time.new.to_s(:db)
    @chat_user.save
  end
    
  def chat_user_env(team)
    @team=Team.find(team)
    
    @crews=Crew.find :all, :conditions => { :team_id => @team.id}
    if @crews.nil? then
      @crews=[]
    else
      @crews=@crews.collect {|p| [ p.title, p.id ] }
    end
    if @team.password_for_game == params[:pass] then
      @check=true
    else
      @check=false
    end
  end

end
