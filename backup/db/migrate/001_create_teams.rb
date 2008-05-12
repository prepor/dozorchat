class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table "teams", :force => true do |t|
      t.string      :title
      t.string      :city
      t.string      :password_for_game
      t.string      :login              
      t.string      :email              
      t.string      :crypted_password,           :limit => 40
      t.string      :password_plain  
      t.string      :salt,                       :limit => 40
      t.datetime    :created_at
      t.datetime    :updated_at
      t.string      :remember_token
      t.datetime    :remember_token_expires_at
      
      
    end
  end

  def self.down
    drop_table "teams"
  end
end
