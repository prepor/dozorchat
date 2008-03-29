class CrewsController < ApplicationController
  before_filter :chat_logined, :only => [:update_where, :update_where2, :get_change_crew_list, :update_title, :get_list]
  def update_where
    @chat_user.crew.where=params[:where]
    if @chat_user.crew.save
      jugg_execute
      render :nothing => true
      # render :update do |page|
      #   page.replace_html "bar_errors", "Статус экипажа изменен"
      # end 
    end
    
  end
  
  def update_where2
    @chat_user.crew.where2=params[:where2]
    if @chat_user.crew.save
      jugg_execute
      render :nothing => true
      # render :update do |page|
      #   page.replace_html "bar_errors", "Статус экипажа изменен"
      # end 
    end
    
  end
  
  def update_title
    @chat_user.crew.title=params[:title]
    if @chat_user.crew.save
      jugg_execute
      render :nothing => true
      # render :update do |page|
      #   page.replace_html "bar_errors", "Название экипажа изменено"
      # end 
    end
    
  end
  
  def get_list
    @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
    @chat_user.last_activity=Time.new.to_s(:db)
    @chat_user.save
    render :update do |page|
      page.replace_html "crews_list", :partial => "chat/crews_list"
    end
  end
  
  def get_change_crew_list
    @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
    render :update do |page|
      page.replace_html "change_crew_div_list", :partial => "chat/change_crew_div_list"
    end
  end
  
  def jugg_execute
    @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
    
    render :juggernaut => {:type => :send_to_channels, :channels => ['team_' + @chat_user.team.id.to_s]} do |page|
        page.replace_html "change_crew_div_list", :partial => "chat/change_crew_div_list"
        page.replace_html "crews_list", :partial => "chat/crews_list"
        page.visual_effect "highlight", "crews_list"
    end
  end
end