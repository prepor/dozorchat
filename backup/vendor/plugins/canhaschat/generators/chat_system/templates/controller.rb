class <%= controller_class_name %>Controller < ApplicationController
  
  def index
    @<%=file_name%> = <%=class_name%>.new(params[:<%=file_name%>])
    if params[:<%=file_name%>]
      if @<%=file_name%>.save
        redirect_to(:action => :start,
                      :id => @<%=file_name%>.id) 
      end
    end
  end
  
  def start
    @<%=file_name%> = <%=class_name%>.find(params[:id])
    @chat_id = @<%=file_name%>.start_chat(@<%=file_name%>.jabber_password)
  end

  def check_for_messages()
    #
    # this method is only useful if you're not using the custom
    # mongrel action
    #
    to = <%=class_name%>.find(params[:id])
    render :text => to.get_messages_from(params[:chat_id],
                                          params[:from]).to_json
  end
  
  def send_message()
    from = <%=class_name%>.find(params[:id])
    begin 
      from.send_message_to(params[:chat_id],
                              params[:to],
                              params[:message],
                              params[:transport])
      render :text => ""
    rescue CanHasChat::Remote::MustSupplyPassword
      flash[:error] = "You must supply a password before you begin chatting."
      raise
    end
  end

end