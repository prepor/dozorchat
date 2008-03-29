class ChatController < ApplicationController
  before_filter :chat_logined
  layout "chat"

  def index

  end
  def show
    @crews_list=Crew.find :all, :conditions => {:team_id => @chat_user.team_id}
    @messages=@chat_user.messages
    if !@messages.first.nil? then
      @chat_user.last_mes=@messages.first.id 
      @chat_user.save
    end
    #debugger
  end
end
