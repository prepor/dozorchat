## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

require 'jabber4r/jabber4r'

class Net::IM::Jabber < Net::IM::Session
	def initialize(roster, username, password, options = {})
		@options = {
			:resource => "NetIM",
			:port => 5222
		}.merge(options)
		@username = username
		@conn = Jabber::Session.bind("#{@username}/#{@options[:resource]}",password,@options[:port])
		
		## set callbacks
		## @conn.add_message_listener {|msg| ...}
		## @conn.add_roster_listener {|evt,obj|
		##	evt in Jabber::Roster::{ITEM_ADDED,ITEM_DELETED,RESOURCE_ADDED,RESOURCE_DELETED,RESOURCE_UPDATED}
	end
	
	def nick=(new_nick)
	end
	
	def status=(new_status)
	end
	
	def sendmsg(user, msg)
		@conn.new_message(user.name).set_body(msg).send
	end
end