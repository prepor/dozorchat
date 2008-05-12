module AuthenticatedTestHelper
  # Sets the current team in the session from the team fixtures.
  def login_as(team)
    @request.session[:team_id] = team ? teams(team).id : nil
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'test') : nil
  end
end
