class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer       :team_id
      t.integer       :id_crew
      t.string        :crew
      t.string        :chat_user
      t.text          :content
      t.string        :private_for
      t.boolean       :is_private, :default => false          
      t.timestamps
    end
    add_index :messages, :team_id
    add_index :messages, :id_crew
  end

  def self.down
    drop_table :messages
    remove_index :messages, :team_id
    remove_index :messages, :id_crew
  end
end
