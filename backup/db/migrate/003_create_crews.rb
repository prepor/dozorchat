class CreateCrews < ActiveRecord::Migration
  def self.up
    create_table :crews do |t|
      t.string      :title
      t.string      :where
      t.string      :where2
      t.integer     :team_id
      t.timestamps
    end
  end

  def self.down
    drop_table :crews
  end
end
