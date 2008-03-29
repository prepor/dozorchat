## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

class Net::IM::Session
	def new(manager, username, password, options = {})
	end
	
	def nick=(new_nick)
	end
	
	def info=(new_info)
	end
	
	def status=(new_status)
	end
	
	def privacy=(new_privacy)
	end
	
	def add_user(user)
	end
	
	def allow_user(user)
	end
	
	def block_user(user)
	end
	
	def update_user(user)
	end
	
	def remove_user(user)
	end
	
	def add_group(group)
	end
	
	def add_user_to_group(user, group)
	end
	
	def remove_user_from_group(user, group)
	end
	
	def update_group(group)
	end
	
	def remove_group(group)
	end
	
	def sendmsg(user, msg)
	end
	
	def disconnect
	end
end