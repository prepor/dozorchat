class CreateMessagesChatUsers < ActiveRecord::Migration
  def self.up
    create_table :messages_chat_users, :id => false do |t|
      t.integer       :message_id, :null => false 
      t.integer       :crew_id, :null => false
    end
    add_index :messages_chat_users, :message_id
    add_index :messages_chat_users, :crew_id
  end

  def self.down
    remove_index :messages_chat_users, :message_id
    remove_index :messages_chat_users, :crew_id
  end
end
