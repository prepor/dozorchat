class <%= class_name %> < ActiveRecord::Base
  can_has_chat  :user_attribute => :jabber_name,
                :log_chats => false,
                :namespace => "my_new_chat_application",
                :transports => {
                  :aim => [:aim_name, :aim_password],
                  :icq => [:icq_name, :icq_password],
                  :yahoo => [:yahoo_name, :yahoo_password],
                  :google => [:google_name, :google_password]
                }
end