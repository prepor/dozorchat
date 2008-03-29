# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 7) do

  create_table "chat_users", :force => true do |t|
    t.integer  "team_id"
    t.integer  "crew_id"
    t.datetime "last_activity"
    t.integer  "last_mes",      :default => 0
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "chat_users", ["team_id"], :name => "index_chat_users_on_team_id"
  add_index "chat_users", ["crew_id"], :name => "index_chat_users_on_crew_id"
  add_index "chat_users", ["last_activity"], :name => "index_chat_users_on_last_activity"

  create_table "crews", :force => true do |t|
    t.string   "title"
    t.string   "where"
    t.string   "where2"
    t.integer  "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "team_id"
    t.integer  "id_crew"
    t.string   "crew"
    t.string   "chat_user"
    t.text     "content"
    t.string   "private_for"
    t.boolean  "is_private",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["team_id"], :name => "index_messages_on_team_id"
  add_index "messages", ["id_crew"], :name => "index_messages_on_id_crew"

  create_table "messages_chat_users", :id => false, :force => true do |t|
    t.integer "message_id", :null => false
    t.integer "crew_id",    :null => false
  end

  add_index "messages_chat_users", ["message_id"], :name => "index_messages_chat_users_on_message_id"
  add_index "messages_chat_users", ["crew_id"], :name => "index_messages_chat_users_on_crew_id"

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.text     "content"
    t.boolean  "is_textile"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "teams", :force => true do |t|
    t.string   "title"
    t.string   "city"
    t.string   "password_for_game"
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "password_plain"
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

end
