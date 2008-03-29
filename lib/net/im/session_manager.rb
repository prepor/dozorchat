## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

class Net::IM::SessionManager
	attr_reader :roster
	def initialize()
		@roster = Net::IM::Roster.new(self)
		@connections = []
		#@poll = Thread.new { loop { sleep 3600 } }
	end
	
	def connect(network, user, pwd, opts = {})
		require "net/im/drivers/#{network.downcase}"
		
		session_klass = eval "Net::IM::#{network}"
		c = session_klass.send(:new, @roster,user,pwd,opts)
		@connections << c
		
		return c
	end
	
	## TBI sendmsg(to, msg)
	
	## TBI cb_message_received
end
