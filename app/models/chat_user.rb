class ChatUser < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  belongs_to :team
  belongs_to :crew
  def messages
    Message.find_by_sql "SELECT * FROM messages as mes LEFT JOIN messages_chat_users as rel ON mes.id = rel.message_id AND rel.crew_id = #{self.crew_id} WHERE (mes.is_private = 0 OR (mes.is_private = 1 AND (mes.id = rel.message_id OR mes.id_crew = #{self.crew_id}))) AND mes.team_id = #{self.team_id} ORDER BY created_at DESC LIMIT 100"
  end
  def messages_update(last_mes)
    Message.find_by_sql "SELECT * FROM messages as mes LEFT JOIN messages_chat_users as rel ON mes.id = rel.message_id AND rel.crew_id = #{self.crew_id} WHERE (mes.is_private = 0 OR (mes.is_private = 1 AND (mes.id = rel.message_id OR mes.id_crew = #{self.crew_id}))) AND mes.team_id = #{self.team_id} AND id > '" + last_mes.to_s + "' ORDER BY created_at DESC LIMIT 100"
  end
    
end
