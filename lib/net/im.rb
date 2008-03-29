## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

module Net; module IM

	## exceptions
	class AuthenticationError < Exception; end
	class SocketError < Exception; end

	## as DBI.drivers
	def self.drivers
		return Dir.glob(File.join(File.dirname(__FILE__),'im','drivers','*.rb')).map {|x| File.basename(x,'.rb')}
	end
	
end; end ## End of Net::IM

require 'net/im/session_manager'
require 'net/im/roster'
require 'net/im/session'
require 'net/im/user'
require 'net/im/group'

