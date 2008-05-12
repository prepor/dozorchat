Message.find(:all, :conditions => ["id > ?", 138]).each do |mes| 
  time=mes.created_at+(12.hours) 
  puts "#{time.strftime("%H:%M:%S")} #{mes.crew}[#{mes.chat_user}] #{mes.content}"
end