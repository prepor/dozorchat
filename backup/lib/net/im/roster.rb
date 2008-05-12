## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

class Net::IM::Roster
	attr_reader :users, :groups

	def initialize(manager)
		@manager = manager
		@users = {}
		@groups = {}
	end
	
	## 
	## User management functions of the roster
	##
	## This includes buddies, people who have the account in their buddy lists,
	## people who are allowed/blocked and people who are currently in chat rooms.
	##
	def add_user(session, name, nick = nil, info = {})
		user = Net::IM::User.new(self, session, name, nick, info)
		@users[user.name] = user
	end
	
	def rename_user(old_name, new_name)
		user = @users[old_name]
		if user
			@users.delete(old_name)
			user.name = new_name
			@users[new_name] = user
			return true
		end
		return false
	end
	
	def remove_user(username)
		user = @users[username]
		if user
			@users.delete(username)
			user.remove
		end
		return user
	end
	
	## return first matching user or nil
	def user(username)
		return @users[username]
	end
	
	##
	## Misc user functions
	##
	def buddies
		## Any user who is in our 'forward' list
		return @users.select {|un,u| u.is_buddy?}
	end
	
	def sendmsg(username, msg)
		u = @users[username]
		return (u ? u.sendmsg(msg) : nil)
	end
	
	##
	## Group management functions of the roster
	##
	## This includes groups in which we have users. These are maintained across 
	## IM networks. IE If a group is created, it is created in all the IM
	## accounts.
	##
	def add_group(info)
		## TBI
	end
	
	def rename_group(old_name)
		## TBI
	end
	
	def remove_group(name)
		## TBI
	end
	
	def group(name)
		## TBI
	end
end