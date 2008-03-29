class CleanerWorker < BackgrounDRb::MetaWorker
  set_worker_name :cleaner_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
    add_periodic_timer(60) { expire_sessions }
  end
  
  def expire_sessions
    ChatUser.find(:all, :conditions => ["last_activity < ?", (Time.now - 1.minutes).to_s(:db)]).each do |user|
      crew=user.crew
      user.destroy
      crew.destroy if crew.chat_users.length < 1
    end
    
  end
end

