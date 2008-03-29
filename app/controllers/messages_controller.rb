class MessagesController < ApplicationController
  before_filter :chat_login_required
  def index
    @messages=@chat_user.messages
  end
  
  def get_new
    @messages=@chat_user.messages_update(@chat_user.last_mes)
    if !@messages.first.nil? then
      @chat_user.last_mes=@messages.first.id
      @chat_user.save
    end

  end
  
  def new
  end

  def create
    @message=Message.new
    
    @message.team=@chat_user.team
    @message.id_crew=@chat_user.crew.id
    @message.crew=@chat_user.crew.title
    @message.chat_user=@chat_user.name
    @message.content=params[:content]
    @message.save
    
    if !params[:privates].empty? then
      #debugger
      channels = ['crew_' + @chat_user.crew.id.to_s]
      @message.is_private=true
      array=params[:privates].split(",")
      array.each do |crew_id|
        channels << ('crew_' + crew_id.to_s)
        rel=MessageRel.new
        rel.message_id=@message.id
        rel.crew_id=crew_id
        rel.save
      end
      @message.private_for = params[:private_for]
      @message.save
      
    else
      channels = ['team_' + @chat_user.team.id.to_s]
    end
    # puts channels.inspect
    @messages = [@message]
    render :juggernaut => {:type => :send_to_channels, :channels => channels} do |page|
        page.insert_html :top, "messages", :partial => 'chat/messages'
        page.visual_effect "highlight", "messages"
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
