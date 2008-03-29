class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= table_name %>", :force => true do |t|
      # this file just puts together the basics for communicating
      # to jabber and other IM networks.  best efforts in security
      # would dictate encrypting IM passwords and nicks in this db,
      # as well as doing some level of password + salt hashing for
      # the jabber name / jabber password.  quite coincientally,
      # at least part of that can be achieved by using acts_as_authenticated.
      # (or using it as a jumping off point)
      t.column :jabber_name, :string
      t.column :jabber_password, :string
      t.column :aim_name, :string
      t.column :aim_password, :string
      t.column :yahoo_name, :string
      t.column :yahoo_password, :string
      t.column :icq_name, :string
      t.column :icq_password, :string
      t.column :google_name, :string
      t.column :google_password, :string
    end
  end

  def self.down
    drop_table "<%= table_name %>"
  end
end
