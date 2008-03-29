module AuthenticatedSystem
  protected
    # Returns true or false if the team is logged in.
    # Preloads @current_team with the team model if they're logged in.
    def logged_in?
      current_team != :false
    end

    # Accesses the current team from the session.  Set it to :false if login fails
    # so that future calls do not hit the database.
    def current_team
      @current_team ||= (login_from_session || login_from_basic_auth || login_from_cookie || :false)
    end

    # Store the given team id in the session.
    def current_team=(new_team)
      session[:team_id] = (new_team.nil? || new_team.is_a?(Symbol)) ? nil : new_team.id
      @current_team = new_team || :false
    end

    # Check if the team is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the team
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_team.login != "bob"
    #  end
    def authorized?
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the team is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to new_session_path
        end
        format.any do
          request_http_basic_authentication 'Web Password'
        end
      end
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_team and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_team, :logged_in?
    end

    # Called from #current_team.  First attempt to login by the team id stored in the session.
    def login_from_session
      self.current_team = Team.find(session[:team_id]) if session[:team_id]
    end

    # Called from #current_team.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |username, password|
        self.current_team = Team.authenticate(username, password)
      end
    end

    # Called from #current_team.  Finaly, attempt to login by an expiring token in the cookie.
    def login_from_cookie
      team = cookies[:auth_token] && Team.find_by_remember_token(cookies[:auth_token])
      if team && team.remember_token?
        team.remember_me
        cookies[:auth_token] = { :value => team.remember_token, :expires => team.remember_token_expires_at }
        self.current_team = team
      end
    end
end
