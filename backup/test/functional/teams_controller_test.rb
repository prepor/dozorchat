require File.dirname(__FILE__) + '/../test_helper'
require 'teams_controller'

# Re-raise errors caught by the controller.
class TeamsController; def rescue_action(e) raise e end; end

class TeamsControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :teams

  def setup
    @controller = TeamsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_allow_signup
    assert_difference 'Team.count' do
      create_team
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'Team.count' do
      create_team(:login => nil)
      assert assigns(:team).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'Team.count' do
      create_team(:password => nil)
      assert assigns(:team).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'Team.count' do
      create_team(:password_confirmation => nil)
      assert assigns(:team).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'Team.count' do
      create_team(:email => nil)
      assert assigns(:team).errors.on(:email)
      assert_response :success
    end
  end
  

  protected
    def create_team(options = {})
      post :create, :team => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
end
