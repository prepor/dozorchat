require File.dirname(__FILE__) + '/../test_helper'

class TeamTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :teams

  def test_should_create_team
    assert_difference 'Team.count' do
      team = create_team
      assert !team.new_record?, "#{team.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference 'Team.count' do
      u = create_team(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference 'Team.count' do
      u = create_team(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'Team.count' do
      u = create_team(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference 'Team.count' do
      u = create_team(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    teams(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal teams(:quentin), Team.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    teams(:quentin).update_attributes(:login => 'quentin2')
    assert_equal teams(:quentin), Team.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_team
    assert_equal teams(:quentin), Team.authenticate('quentin', 'test')
  end

  def test_should_set_remember_token
    teams(:quentin).remember_me
    assert_not_nil teams(:quentin).remember_token
    assert_not_nil teams(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    teams(:quentin).remember_me
    assert_not_nil teams(:quentin).remember_token
    teams(:quentin).forget_me
    assert_nil teams(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    teams(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil teams(:quentin).remember_token
    assert_not_nil teams(:quentin).remember_token_expires_at
    assert teams(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    teams(:quentin).remember_me_until time
    assert_not_nil teams(:quentin).remember_token
    assert_not_nil teams(:quentin).remember_token_expires_at
    assert_equal teams(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    teams(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil teams(:quentin).remember_token
    assert_not_nil teams(:quentin).remember_token_expires_at
    assert teams(:quentin).remember_token_expires_at.between?(before, after)
  end

protected
  def create_team(options = {})
    Team.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end
end
