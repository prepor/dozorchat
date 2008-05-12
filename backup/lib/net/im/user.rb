## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

require 'uri'

## IM Common User fields:
## - name
## - nick
## - status

## Anything else can be stored in the 'info' hash

class Net::IM::User
    attr_reader :name, :nick, :info
    
	def initialize(roster, session, name, nick = nil, info = {})
		@roster = roster		## roster this user is part of
		@session = session	## session this user is part of
		@name = name		## account name on the network
		@nick = nick		## nick name of this user
		@info = info		## any other infomation about this user
		
		@is_buddy = false	## is this user a buddy?
		@in_reverse = false	## does this user have us as a buddy?
		@is_blocked = false	## is this user blocked?
		@is_allowed = false	## is this user allowed?
	end
	
	def safenick
		return URI::encode(@nick || @name)
	end
	
	def nick=(new_nick)
		@session.rename_user(user, new_nick)
		@nick = new_name
	end
	
	def buddy?
		return @is_buddy
	end
	
	def buddy=(bool)
		return if bool == @is_buddy
		if bool
			@session.add_user(self)
		else
			@session.remove_user(self)
		end
		@is_buddy = bool
	end
	
	def reverse?
		return @in_reverse
	end
	
	def blocked?
		return @is_blocked
	end
	
	def blocked=(bool)
		allowed = !bool
	end
	
	def allowed?
		return @is_allowed
	end
	
	def allowed=(bool)
		return if bool = @is_allowed
		if bool
			@session.allow_user(user)
		else
			@session.block_user(user)
		end
		@is_allowed = bool
		@is_blocked = !bool
	end
	
	def remove
		allowed = false
		buddy = false
	end
	
	def sendmsg(msg)
		@session.sendmsg(user, msg)
	end
	
	def groups
		## TBI
	end
	
	def add_to_group(group)
		## TBI
	end
	
	def remove_from_group(group)
		## TBI
	end
	
	##
	## private functions used by the driver
	## these are used when the user info is synced with the server
	## by server initiated messages
	##
	
	def set_nick(new_nick)
		@nick = new_nick
	end

	def set_status(new_status)
		@status = new_status
	end

	def set_buddy(bool)
		@is_buddy = bool
	end

	def set_reverse(bool)
		@in_reverse = bool
	end
	
	def set_allowed(bool)
		@is_allowed = bool
	end
	
	def set_blocked(bool)
		@is_blocked = bool
	end
end