class CreateChatUsers < ActiveRecord::Migration
  def self.up
    create_table :chat_users do |t|
      t.integer       :team_id
      t.integer       :crew_id
      t.datetime      :last_activity
      t.integer       :last_mes, :default => 0
      t.string        :name
      t.timestamps
    end
    add_index :chat_users, :team_id
    add_index :chat_users, :crew_id
    add_index :chat_users, :last_activity
  end

  def self.down
    drop_table :chat_users
    remove_index :chat_users, :team_id
    remove_index :chat_users, :crew_id
    remove_index :chat_users, :last_activity
  end
end
