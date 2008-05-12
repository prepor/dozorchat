# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout "main"
  include AuthenticatedSystem
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  def chat_login_required
    if session[:chat_user].nil?
      flash[:error] = "Вы должны авторизироваться"
      if params[:team_id].nil?
        redirect_to root_path
      else
        redirect_to chat_path(params[:team_id])
      end
    else
      @chat_user=session[:chat_user]
    end
  end
  
  def chat_logined
    if session[:chat_user].nil? then
      if params[:team_id].nil? then
        redirect_to root_path
      else
        redirect_to :controller => "chat_users", :action => "new", :team_id => params[:team_id]
      end
    else
      @chat_user=session[:chat_user]
      if !ChatUser.find_by_id(@chat_user.id) then
        session[:chat_user]=nil
        redirect_to :controller => "chat_users", :action => "new", :team_id => @chat_user.team_id
      end
    end
  end
  protect_from_forgery :secret => 'f5becaf952baf4213asdafasdec5178f2cec8sdfgsdfgsdfgea'
end
