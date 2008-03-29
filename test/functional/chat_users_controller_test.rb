require File.dirname(__FILE__) + '/../test_helper'
require 'chat_users_controller'

# Re-raise errors caught by the controller.
class ChatUsersController; def rescue_action(e) raise e end; end

class ChatUsersControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :chat_users

  def setup
    @controller = ChatUsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_allow_signup
    assert_difference 'ChatUser.count' do
      create_chat_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'ChatUser.count' do
      create_chat_user(:login => nil)
      assert assigns(:chat_user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'ChatUser.count' do
      create_chat_user(:password => nil)
      assert assigns(:chat_user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'ChatUser.count' do
      create_chat_user(:password_confirmation => nil)
      assert assigns(:chat_user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'ChatUser.count' do
      create_chat_user(:email => nil)
      assert assigns(:chat_user).errors.on(:email)
      assert_response :success
    end
  end
  

  protected
    def create_chat_user(options = {})
      post :create, :chat_user => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
end
