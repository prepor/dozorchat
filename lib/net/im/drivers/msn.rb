## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

require 'socket'
require "webrick/httputils"
require "net/https"
require 'digest/md5'

## TODO:
# support SYN command
# support  GTC and BLP
# support multiple groups for buddies
# support adding/removing contacts to groups and better group support (with guids)
# support multiple buddy chats
# support multi-user chats
# support personal message (UUX/UBX)
# add verification for passport_auth

class Net::IM::MSN < Net::IM::Session
	STATUS_TABLE = {
		'online'		=> 'NLN',
		'away'		=> 'AWY',
		'busy'		=> 'BSY',
		'brb'		=> 'BRB',
		'phone'		=> 'PHN',
		'lunch'		=> 'LUN',
		'invisible'	=> 'HDN',
		'idle'		=> 'IDL',
		'offline'		=> 'FLN'
	}

	ERRORTABLE = {
		-10 => 'Local error',
		200 => 'Syntax error',
		201 => 'Invalid parameter',
		205 => 'Invalid user',
		206 => 'Domain name missing',
		207 => 'Already logged in',
		208 => 'Invalid username',
		209 => 'Invalid fusername',
		210 => 'User list full',
		215 => 'User already there',
		216 => 'User already on list',
		217 => 'User not online',
		218 => 'Already in mode',
		219 => 'User is in the opposite list',
		280 => 'Switchboard failed',
		281 => 'Transfer to switchboard failed',
		300 => 'Required field missing',
		302 => 'Not logged in',
		500 => 'Internal server error',
		501 => 'Database server error',
		510 => 'File operation failed',
		520 => 'Memory allocation failed',
		540 => 'Failed challenge request',
		600 => 'Server is busy',
		601 => 'Server is unavaliable',
		602 => 'Peer nameserver is down',
		603 => 'Database connection failed',
		604 => 'Server is going down',
		707 => 'Could not create connection',
		711 => 'Write is blocking',
		712 => 'Session is overloaded',
		713 => 'Too many active users',
		714 => 'Too many sessions',
		715 => 'Not expected',
		717 => 'Bad friend file',
		911 => 'Authentication failed',
		913 => 'Not allowed when offline',
		920 => 'Not accepting new users'
	}

	class ClientID
		CAPS = {
			:mobile => 0x1,
			:reset => 0x2,
			:gif_ink => 0x4,
			:isk_ink => 0x8,
			:video_cat => 0x10,
			:multipacket_messaging => 0x20,
			:mob => 0x40,
			:direct => 0x80,
			:web_client => 0x200,
			:office_live => 0x800,
			:direct_im => 0x4000,
			:winks => 0x8000,
			:msn_search => 0x10000,
			:voice_clips => 0x40000,
			:msnc1 => 0x10000000,
			:msnc2 => 0x20000000,
			:msnc3 => 0x30000000,
			:msnc4 => 0x40000000,
			:msnc5 => 0x50000000,
			:msnc6 => 0x60000000
		}
		MSN70 = 0x4000c024
		
		def initialize(cid)
			@cid = cid.to_i
		end
		
		def msnc_version
			(@cid/0x10000000).to_i
		end
		
		def capabilities
			caps = []
			CAPS.each {|k,v|
				caps << k if @cid & v == v
			}
			return caps
		end
		
		def method_missing(sym)
			cap = sym.to_s.chomp('?').to_sym
			unless sym.to_s[-1,1] == '?' && CAPS.has_key?(cap)
				raise NoMethodError, "undefined method `#{sym}' for #{self.inspect}"
			end
			return (@cid & CAPS[cap] == CAPS[cap])
		end
	end
	
	class Chat
		## a Chat is a SwitchBoard in MSNP talk
	
		attr_reader :fd, :emails, :state
		
		def self.new_invitation(sess, email)
			chat = self.new(sess, 'invite', sess.tid)
			chat.emails << email
			sess.send("XFR","SB")
			return chat
		end
		
		def self.new_answer(sess, email, endpoint, hash, sid)
			chat = self.new(sess, 'answer', sid)
			chat.emails << email
			unless sess.roster.user(email)
				sess.roster.add_user(sess, email)
			end
			sess.roster.user(email).info[:chat] = chat
			chat.connect(endpoint, hash)
			return chat
		end
		
		def mq; @queue; end
		
		def initialize(sess, type, xid)
			@session = sess		## the main MSN session we are part of
			
			## required
			@fd = nil			## connection fd
			@state = 'xf'		## connection state; cp (pending), xf (not connected), re (ready), an/us (connected)
			@emails = []		## emails we talk to through this chatroom (should this be buddies?)
			@queue = []		## outgoing message queue
			@type = type		## answer or invite
			@tid = 1			## current transaction id
	
			## less questionable
			@endpoint = nil		## remote ip:port (or can we get this from fd)
			@hash = nil		## server-sent hash
			
			## variable variable; session_id IFF 'answer', orig_tid IFF 'invite'
			@session_id = xid	## server sesstion id
			@orig_tid = xid		## original tid of the XFR
		end
		
		## possible states of a connection
		def pending_answer?
			return (@type == 'answer' && @state == 're')
		end
		
		def pending_announce?
			return (@type == 'invite' && @state == 're')
		end
		
		def pending_answer_reply?
			return (@type == 'answer' && @state == 'an')
		end
		
		def waiting_request?
			return @state == 'xf'
		end
		
		def established?
			return @state == 'es'
		end
		
		def pending_flush?
			return !@queue.empty? && established?
		end
		
		def waiting_in?
			return (@state != 'xf') && (@state != 're')
		end
		
		def waiting_out?
			return (@state == 're') || established?
		end
		## end of possible states
		
		## state modifiers		
		def connect(endpoint,hash)
			@endpoint = endpoint
			@hash = hash
			begin
				ip,port = @endpoint.strip.split(/:/)
				@fd = TCPSocket.new(ip,port.to_i)
			rescue
				## remove chatroom
				raise 'SocketError'
			end
			@state = 're'
		end
	
		def answer
			send('ANS', "#{@session.email} #{@hash} #{@session_id}")
			@state = 'an'
			return
		end
		
		def announce
			send('USR', "#{@session.email} #{@hash}")
			@state = 'us'
			return
		end
		## end of state modifiers
		
		def match_request?(otid)
			return (@orig_tid.to_i == otid.to_i)
		end
	
		def close
			## close this chatroom
			@emails.each {|e|
				@session.roster.user(e).info[:chat] = nil if @session.roster.user(e)
			}
			begin
				send("BYE",@session.email)
				@fd.close
			rescue
				## if we fail here it doesn't matter!
				;
			end
		end
		
		def invite(email)
			send("CAL",email)
			@state = 'ca' if @state == 'us'
		end
		
		def queue(msg)
			@queue << msg
			return 1
		end
		def flush
			## this could block on multiple writes
			#@queue.each {|msg|
			#	header = "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n"
			#	buf = URI::encode(header + msg)
			#	params = "A #{buf.size}\r\n" + buf
			#	send("MSG", params, true)
			#}
			#@queue = []
			unless @queue.empty?
				msg = @queue.shift
				header = "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n"
				buf = header + URI::encode(msg)
				#nick = @session.nick || @session.email
				#@fd.write("MSG #{@session.email} #{URI::encode(nick)} #{buf.size}\r\n" + buf)
				#@fd.write("MSG A #{buf.size}\r\n" + buf)
				#p ["CHAT MSG >>",buf]
				params = "A #{buf.size}\r\n" + buf
				send("MSG", params, true)
			end
		end
	
		def send(cmd, params = nil, raw = false)
			msg = "#{cmd} #{@tid}"
			@tid += 1
			msg << " #{params}" if params
			msg << "\r\n" unless raw
			
			#p ['CHAT >>>',msg]
			return @fd.write(msg)
		end
		
		def recv
			buf = @fd.gets.to_s.chomp
			return [nil,nil,nil] if buf == ''
			
			#p ["CHAT <<<",buf]
			
			pbuf = buf.strip.split(' ')			
			cmd = pbuf.shift
			
			# it's possible that we don't have any params (errors being
			# the most common) so we cover our backs
			if pbuf.length >= 2
				tid = pbuf.shift
				params = pbuf
			elsif pbuf.length == 1
				tid = pbuf.shift
				params = ''
			else
				tid = '0'
				params = ''
			end
	
			#p ["DECODE <<<",cmd,tid,params]
			
			return [cmd, tid, params]
		end
		
		def read
			cmd,tid,params = recv
			return -1 unless cmd
			params = [""] if params == ''
			
			case cmd
			when 'IRO'	## initial roster
				uid, ucount, email, nick = *params[0,4]
				## params[4] == client_cap
				if ucount == '1'
					# do nothing if we only have one participant as we have already added this person
					return
				else
					unless @session.roster.user(email)
						@session.roster.add_user(@session, email)
					end
					@emails << email
					@session.roster.user(email).info[:chat] = self
					## TBI implement friend_joined_chat cb
				end
			when 'ANS'	## answer confirmation
				@state = 'es'
			when 'USR'	## switchboard request initial identification
				send('CAL', @emails[0])
				@state = 'ca'
			when 'CAL'	## call confirmation
				#debug "call confirmation ignored: #{tid}, #{params.join(" ")}"
				;
			when 'JOI'	## session join
				email = tid
				## params[0] == nick, params[1] == client_cap
				# if it's a multi-user chat, just append it to the list
				if !@emails.nil? and email != @emails[0]
					@emails << email
					unless @session.roster.user(email)
						@session.roster.add_user(@session, email)
					end
					@session.roster.user(email).info[:chat] = self
					## TBI implement friend_joined_chat cb
				else
					# otherwise (common path) set up the sbd and flush the messages
					@state = 'es'
					flush()
					## TBI implement friend_chat_setup_done cb
				end
			
			## switchboard control messages
			when 'ACK'	## message acknowledge
				#debug("ACK: tid:#{tid}")
				;
			when 'NAK'	## message negative acknowledgement
				#debug("NAK: tid:#{tid}")
				;
			when 'BYE'	## switchboard user disconnect
				email = tid
				if email != @emails[0]
					@emails.delete(email) if @emails.include?(email)
					## TBI implemented friend_left_chat cb
				else
					close
				end
			
			## main message reception
			when 'MSG'
				joined_params = tid + ' ' + params.join(" ")
				mlen = params.pop().to_i
				#msg = _recvmsg(mlen, nd.fd)
				left = mlen
				buf = ''
				while buf.length != mlen
					c = @fd.read(left.to_i)
					buf << c
					left -= c.length
				end
				msg = URI::decode(buf)
				#p ["CHAT MSG",msg]
				## XXX parse message here!
				## TBI implement recieved_msg cb
				
			## numeric error messages
			else
				# catch server errors - always numeric type
				errno = cmd.to_i
				unless Net::IM::MSN::ERRORTABLE.has_key? errno
					desc = "Unknown error #{cmd}"
				else
					desc = Net::IM::MSN::ERRORTABLE[errno]
				end
				@session.debug ["CHAT ERROR",desc]
			end
	
		end
	end

	attr_accessor :fd, :roster, :tid, :email, :nick, :poll
	
	def debug(a)
		STDERR.puts(a.inspect) if $DEBUG
	end
	
	def initialize(roster,user,pwd,opts = {})
		@options = {
			:login_host => "messenger.hotmail.com",
			:login_port => 1863,
			:passport => "https://nexus.passport.com/rdr/pprdr.asp",
			:default_status => 'online',
			:poll_delay => 0.01
		}.merge(opts)

		## default attribute values
		@fd = nil		# socket fd
		@tid = 1		# transaction id
		
		@roster = roster	# common roster for users/groups
		@email = user	# login email
		@pwd = pwd	# login pwd
		@nick = nil		# nick
		@info = {}		## hash of additional private info
					## home/work/mobile phone

		@status   = 'FLN'		# default status
		
		@last_lst = nil	## state variable		
		## end default values
		
		## login to service; raise exception if this fails
		login()
		
		## sync roaster information
		sync()
		
		## mark us with the default status
		self.status = @options[:default_status] if @options[:default_status]
		
		@poll = Thread.new {
			loop {
				iwtd = []
				owtd = []
				
				chats.each {|chat|
					owtd << chat if chat.waiting_out?
					iwtd << chat if chat.waiting_in?
					#p ['POLL CHAT',chat.emails,chat.state,chat.fd,chat.waiting_out?,chat.waiting_in?,chat.mq]
				}
				
				infd = (iwtd.map {|c| c.fd}.compact << @fd)
				outfd = owtd.map {|c| c.fd}.compact
				debug ['POLL',infd,outfd] unless infd.size == 1
				read_fds, write_fds = IO.select(infd, outfd, nil)
				
				(read_fds + write_fds).each {|fd|
					chat = chats.find {|c| c.fd == fd}
					
					if chat
						begin
							if chat.waiting_out?
								chat.answer if chat.pending_answer?
								chat.announce if chat.pending_announce?
								chat.flush if chat.pending_flush?
							else
								chat.read
							end
						rescue
							#p ['CHAT ERR',$!]
							chat.close
						end
					else
						#begin
							read
						#rescue
						#	disconnect
						#	Thread.current.exit
						#end
					end
				}
				if @options[:poll_delay].to_f > 0.001
					sleep @options[:poll_delay] # sleep a bit so we don't take over the cpu
				end
			}
		}
		@poll.abort_on_exception = true
	end
	
	############ BEGIN REQUIRED FUNCTIONS ####################
	
	def nick=(newnick)
		@nick = newnick
		return send("PRP","#{MFN} " + safenick)
	end
	
	## TBI def info=(new_info)
	
	def status=(newstatus)
		return 0 unless STATUS_TABLE.has_key?(newstatus)
		@status = STATUS_TABLE[newstatus]
		return send("CHG", @status + " " + Net::IM::MSN::ClientID::MSN70.to_s)
		## reset out client_id!
	end
	
#	def privacy(public = 1, auth = 0)
#		_send('BLP', public ? 'AL' : 'BL') # social / cave
#		_send('GTC', auth   ? 'A'  : 'N')  # auth / allow
#		return 1
#	end
	
	def add_user(user)
		send("ADC","FL N=#{user.name} F=#{user.safenick}")
		send("ADC","AL N=#{user.name} F=#{user.safenick}")
		## XXX changes recorded locally by ADD msg back
		return 1
	end
	
	def allow_user(user)
		send("REM","BL #{user.name}")
		send("ADC","AL N=#{user.name}")
	end
	
	def block_user(user)
		send("REM","AL #{user.name}")
		send("ADC","BL N=#{user.name}")
	end
	
	## TBI def update_user(user)
	
	def remove_user(user)
		send("REM","FL #{user.info[:guid]}")
	end

	def add_group(group,parent_group = '0')
		send('ADG', URI::encode(group.name) + ' ' + parent_group)
		## XXX save changes locally?
		return 1
	end
	
	## TBI def add_user_to_group(user, group)
	
	## TBI def remove_user_from_group(user, group)
	
	def remove_group(group)
		send('RMG', group.info[:guid])
		## XXX save changes locally?
		return 1
	end

#	TBI def update_group(group)
#	def rename_group(group, newname)
#		send('REG', group.info[:guid] + ' ' + URI::encode(newname))
#		## XXX save changes locally?
#		return 1
#	end
	
	def disconnect
		@fd.write "OUT\r\n"
		@fd.close
	end
	
	def sendmsg(user, msg = '')
		return -2 if msg.length > 1500 ## maximum size; we should split if this is the case
		user.info[:chat] = Net::IM::MSN::Chat.new_invitation(self, user.name) unless user.info[:chat]
		user.info[:chat].queue(msg)
	end
	############ END OF REQUIRED FUNCTIONS #################

	def sync
		send('SYN', '0 0')
		return 1
	end
	
	def safenick
		return URI::encode(@nick || @email)
	end

	def chats
		return @roster.users.select {|bk,bobj| Net::IM::User === bobj}.map {|bk,b| b.info[:chat]}.compact
	end

	def send(cmd, params = '', raw = false)
		msg = "#{cmd} #{@tid}"
		@tid += 1
		msg << " #{params}" if params
		msg << "\r\n" unless raw
		
		debug ['MAIN >>>',msg]
		xlen = @fd.write(msg)
		return xlen
	end

	def recv
		buf = @fd.gets.to_s.chomp
		return [nil,nil,nil] if buf == ''
		
		debug ["MAIN <<<",buf]
		
		pbuf = buf.strip.split(' ')
		cmd = pbuf.shift
		
		# it's possible that we don't have any params (errors being
		# the most common) so we cover our backs
		if pbuf.length >= 2
			tid = pbuf.shift
			params = pbuf
		elsif pbuf.length == 1
			tid = pbuf.shift
			params = ''
		else
			tid = '0'
			params = ''
		end
		
		return [cmd, tid, params]
	end

	def read
		cmd,tid,params = recv
		return -1 unless cmd
		params = [""] if params == ''
		
		case cmd
		when 'CHL'	## challenge
			hash = msnhash('PROD0090YUAUV{2B','YMM8C_H7KCQ2S_KL',params[0])
			send("QRY", "PROD0090YUAUV{2B 32\r\n" + hash,true)
			@dbg_lst_chl = [params[0],hash]
			@dbg_chl_cnt ||= 0
			@dbg_chl_cnt += 1
			@dbg_chl_fail ||= 0
			p ["CHL",@dbg_chl_cnt,@dbg_chl_fail]
		when 'QRY'	## query response
			; # ignored
		when 'ILN'	## status notification
			status,email = params[0,2]
			nick = (params.size > 2 ? URI::decode(params[2]) : '')
			clientid = params[3]
			@roster.user(email).set_status(status)
			@roster.user(email).set_nick(nick)
		when 'CHG'	## status change
			; # ignored
		when 'OUT'	## server disconnect
			; # ignored
			## TBI this needs to be marked and an error raised on the next _send/fd.write attempt
		when 'FLN'	## status offline
			email = tid
			@roster.user(email).set_status('FLN')
		when 'NLN'	## status notification
			status = tid
			email = params[0]
			nick = (params.size > 1 ? URI::decode(params[1]) : '')
			clientid = params[2]
			@roster.user(email).set_status(status)
			@roster.user(email).set_nick(nick)
		when 'BLP'	## privacy mode change
			; # ignored
		when 'LST'	## list requests
			params.unshift(tid)
			
			guid = nil
			email = nil
			nick = nil
			groups = []
			listmask = 0
			
			if params[0][0,2] == "N="
				email = params[0][2,params[0].size-2]
				params.shift
			end
			if params[0][0,2] == "F="
				nick = URI::decode(params[0][2,params[0].size-2])
				params.shift
			end
			if params[0][0,2] == "C="
				guid = params[0][2,params[0].size-2]
				params.shift
			end
			listmask = params.shift.to_i
			buddy_account_type = params.shift.to_i
			groups = params.shift.to_s.split(/,/)
			
			user = nil
			unless @roster.user(email)
				## XXX fix the groups here
				@roster.add_user(self, email, nick, {:guid => guid, :groups => groups})
			end
			user = @roster.user(email)
			
			if(listmask & 16 == 16)
				## user id pending onto our reverse list
				send("ADC","RL N=#{user.name}")
				send("REM","PL #{user.name}")
				user.set_reverse true
			end
			user.set_reverse(listmask & 8 == 8)
			user.set_blocked(listmask & 4 == 4)
			user.set_allowed(listmask & 2 == 2)
			user.set_buddy(listmask & 1 == 1)
			
			# save in the global last_lst the email, because BPRs might need it
			@last_lst = email
		when 'GTC'	## add notification
			; # ignored
		when 'SYN'	## list sync confirmation
			; # ignored; format = tstamp tstamp # #
		when 'PRP'	## our private info
			param = (params.size > 1 ? URI::decode(params[1]) : '')
			case params[0]
				when 'PHH' then @info[:home_phone] = param
				when 'PHW' then @info[:work_phone] = param
				when 'PHM' then @info[:mobile_phone] = param
				when 'MFN' then @nick = URI::decode(param)
				## also MBE WWE
			end
		when 'LSG'	## group list
			name = tid
			guid = params[0]
			## XXX  groups now handled by the roster
			# @groups[guid] = URI::decode(name)
		when 'BPR'	## user info
			# the email is deduced from the last lst we got; if it's nil it means
			# that we come from an add (the protocol behaves different if coming
			# from SYN or ADD)
			email = @last_lst
			if email && params.size == 1
				# we come from SYN
				type = tid
				param = URI::decode(params.join(" "))
			else
				# we come from ADD
				email = params[0]
				type = params[1]
				param = (params.size >= 3 ? URI::decode(params[2]) : '')
			end
			return unless @roster.user(email)
			case type
				when 'PHH': @roster.user(email).info[:home_phone] = param
				when 'PHW': @roster.user(email).info[:work_phone] = param
				when 'PHM': @roster.user(email).info[:mobile_phone] = param
				when 'HSB': @roster.user(email).info[:has_blog] = (param.to_i == 1)
				## also MOB
			end
		when 'SBS'	## msn mobile credits
			; # ignore
		
		### ROSTER MANAGEMENT FUNCTIONS
		when 'UBX'	## update buddy personal message
			email = tid
			if params[0] == ''
				## do this the hard way, read until </Data>
				ubx = ''
			else
				mlen = params[0].to_i
				ubx = @fd.read(mlen)
			end
			@roster.user(email).info[:ubx] = ubx if @roster.user(email)
		when 'ADC'	## add contact
			type = params[0]
			email = params[1][2,params[1].size-2]
			nick = URI::decode(params[2][2,params[2].size-2]) if params.size > 2
			uid = params[3][2,params[2].size-2] if params.size > 3
			@roaster.add_user(self, email, nick, {:guid => uid}) unless @roster.user(email)
			
			case type
			when 'RL'
				@roster.user(email).set_reverse(true)
				## TBI add 'you were added callback'
			when 'FL'
				@roster.user(email).set_buddy(true)
				# put nil in last_lst so BPRs know it's not coming from sync
				@last_lst = nil
			when "BL"
				@roster.user(email).set_blocked(true)
			when "AL"
				@roster.user(email).set_allowed(true)
			end
		when 'SBP'	## contact info change
			; # ignored
		when 'REM'	## user remove
			type = params[0]
			## XXX whats params[1] ???
			email = params[2]
			list = nil
			
			case type
			when 'RL'
				@roster.user(email).set_reverse(false) if @roster.user(email)
				## TBI add callback
			when 'FL'
				@roster.user(email).set_forward(false) if @roster.user(email)
				@roster.remove_user(email)
			when "BL"
				@roster.user(email).set_blocked(false) if @roster.user(email)
			when "AL"
				@roster.user(email).set_allowed(false) if @roster.user(email)
			end
		
		### GROUP MANAGEMENT FUNCTIONS
		when 'ADG'	## group add
			lver, name, gid = *params[0,3]
			## XXX groups are now managed by the roster
			## @groups[gid] = name
		when 'RMG'	## group remove
			lver, gid = *params[0,2]
			@roster.keys.each {|e|
				if @roster.user(e) && @roster.user(e).gid == gid
					@roster.user(e).set_forward = false
					@roster.remove_user(e)
				end
			}
			## have to get group via roster
			## @roster.remove_group(gid)
		when 'REG'	## group rename
			## XXX whats params[0] ???
			gid, name = *params[0,2]
			## XXX fix for roster
			## @roster.add_group(gid, name)
			
		### CHAT SETUP FUNCTIONS
		when 'RNG'	## switchboard invitation
			sid = tid
			ipport = params[0]
			## params[1] == 'CKI'
			hash = params[2]
			email = params[3]
			## nick = URI::decode(params[4])
			
			## XXX we should just have to create the chat, not also link it to this user!
			@roster.user(email).info[:chat] = Chat.new_answer(self, email, ipport, hash, sid)
		when 'XFR'	## switchboard request
			## XXX what are params[0] and params[2] ???
			ipport = params[1]
			hash = params[3]
			
			chat = chats.find {|c| c.waiting_request? && c.match_request?(tid)}
			raise "XFR error; no matching chatroom" unless chat
			## XXX switch to warning instead of bombing out how thing!
			
			chat.connect(ipport,hash)
		## XXX will these ever happen?
		when 'ACK'	## message acknowledge
			;
		when 'NAK'	## message negative acknowledgement
			;
		
		## CONTROL MESSAGES COME IN AS MSG
		## main message reception
		when 'MSG'
			joined_params = tid + ' ' + params.join(" ")
			mlen = params.pop().to_i
			msg = @fd.read(mlen)
			# debug("MESSAGE\n+++ Header: #{joined_params.to_s}\n#{msg}\n\n")
			## TBI implement cb message_received

		## NUMERIC ERROR FUNCTIONS
		else
			# catch server errors - always numeric type
			errno = cmd.to_i
			unless ERRORTABLE.has_key? errno
				desc = "Unknown error #{cmd}"
			else
				desc = ERRORTABLE[errno]
			end
			if errno == 540
				## failed challenge
				@dbg_chl_fail ||= 0
				@dbg_chl_fail += 1
				p ["Failed CHL",@dbg_chl_cnt,@dbg_chl_fail,@dbg_lst_chl]
				@dbg_lst_chl = nil
				begin
					disconnect
				rescue
					; # ignore failure
				end
				
				## login to service; raise exception if this fails
				login()
				
				## sync roaster information
				sync()
				
				## mark us with the default status
				self.status = @options[:default_status] if @options[:default_status]
			end
			### XXX on 5xx series error, close fd and reconnect!
			# debug("SERVER ERROR #{errno}: #{desc} - #{tid}, #{params.join(" ")}")
		end
		return
	end

	private
	def login(host = @options[:login_host], port = @options[:login_port])
		# open socket
		begin
			@fd.close
		rescue
			; # ignore failure as we are about to replace it anyways
		end
		@fd = TCPsocket.new(host,port)
		@fd.sync = true
		@fd.binmode
		
		# version information
		send('VER', 'MSNP12 CVR0') #MSNP11 MSNP10 MSNP9 MSNP8
		
		cmd,tid,params = recv()
		if cmd != 'VER' and params[0] != 'MSNP12'
			raise AuthenticationError, "MSN protocol version mismatch with Login Server"
		end
		
		# lie the version, just in case
		send('CVR', '0x0409 win 5.1 i386 MSNMSGR 7.0.0813 MSMSGS ' + @email)
		# ignore the return value
		recv()  ## should echo CVR
		
		# auth send user, get hash or notification server
		send('USR', 'TWN I ' + @email)
		
		cmd,tid,params = recv()
		if cmd == 'XFR'
			if params[0] == 'NS'
				## reconnect to NS server and start over
				ns_ip, ns_port = *(params[1].split(/:/))[0,2]
				return login(ns_ip, ns_port.to_i)
			else
				raise AuthenticationError,"Failed to obtain MSN Notification Server"
			end
		elsif !(cmd == "USR" && params[1] == "S")
			raise AuthenticationError,"Failed to obtain MSN Notification Server or continuation"
		end
		
		# get and use the passport id
		passportid = passport_auth(params[2])
		send('USR', 'TWN S ' + passportid)
		
		cmd,tid,params = recv()
		unless cmd == 'USR' && params[0] == 'OK'
			raise AuthenticationError, "Failed to authenticate to MSN"
		end
		## params 1 also holds the 'account verified' flag
		## params 2 may also be kids?
		
		cmd,tid,params = recv() ## SBS message, ignore
		unless cmd == "SBS"
			raise AuthenticationError,"Failed to receive expected SBS message"
		end
		
		cmd,tid,params = recv() ## get Profile info
		unless cmd == "MSG" && tid == "Hotmail"
			raise AuthenticationError,"Failed to receive profile information" 
		end
		mlen = params.pop.to_i
		profile = @fd.read(mlen)
		
		## XXX parse profile here!
		
		return profile
	end

	def passport_auth(hash)
		# initial connection
		nuri = URI.parse(@options[:passport])
		nexus = Net::HTTP.new(nuri.host, nuri.port)
		nexus.verify_mode = OpenSSL::SSL::VERIFY_NONE
		nexus.use_ssl = true
		response = nexus.get(nuri.request_uri)
		purl = response["PassportURLs"]
		
		# parse the info
		d = {}
		purl.split(',').each { |i|
			i =~ /^(.*?)=(.*)$/
			d[$1] = $2
		}
		
		# get the login server
		login_server = 'https://' + d['DALogin']
		
		# build the authentication headers
		ahead =  'Passport1.4 OrgVerb=GET'
		ahead << ',OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom'
		ahead << ',sign-in=' + @email.sub(/@/,"%40") # BUG
		ahead << ',pwd=' + @pwd
		ahead << ',lc=1033,id=507,tw=40,fs=1,'
		ahead << 'ru=http%3A%2F%2Fmessenger%2Emsn%2Ecom,ct=1062764229,'
		ahead << 'kpp=1,kv=5,ver=2.1.0173.1,tpf=' + hash
		headers = { 'Authorization' => ahead }
		
		# connect to the given server
		loginuri = URI.parse(login_server)
		ls = Net::HTTP.new(loginuri.host, loginuri.port)
		ls.verify_mode = OpenSSL::SSL::VERIFY_NONE
		ls.use_ssl = true
		
		# make the request
		req = Net::HTTP::Get.new(login_server, headers)
		resp = ls.request req
		
		# loop if we get redirects until we get a definitive answer
		while resp.is_a? Net::HTTPFound
			login_server = resp["Location"]
			loginuri = URI.parse(login_server)
			ls = Net::HTTP.new(loginuri.host, loginuri.port)
			ls.use_ssl = true
			headers = { 'Authorization' => ahead }
			req = Net::HTTP::Get.new(login_server, headers)
			resp = ls.request req
		end
		
		# now we have a definitive answer, if it's not 200 (success) raise error
		unless resp.is_a? Net::HTTPOK
			raise AuthenticationError, "Failed to authenticate to Passport"
		end
		
		# otherwise parse the headers to get the passport id
		ainfo = resp['Authentication-Info'] || resp['WWW-Authenticate']
		
		# parse the info
		d = {}
		ainfo.split(',').each { |i|
			i =~ /^(.*?)=(.*)$/
			d[$1] = $2
		}
		
		passportid = d['from-PP'].dup
		passportid.slice!(0)
		passportid.slice!(-1)
		return passportid
	end

	## see http://msnpiki.msnfanatic.com/index.php/Notification:Challenges
	def msnhash(prodid, prodkey, chlstr)
		md5 = Digest::MD5.hexdigest(chlstr + prodkey)
		chlx = (0..3).map {|i|
			((md5[8*i+6,2] + md5[8*i+4,2] + md5[8*i+2,2] + md5[8*i,2]).to_i(16) & 0x7fffffff)
		}
		
		qrystr = chlstr + prodid
		qrystr << '0'*(8-(qrystr.size%8)) ##unless qrystr.size%8 == 0
		qryx = (0...(qrystr.size/4)).map {|i|
			(qrystr[4*i+3] << 24) | (qrystr[4*i+2] << 16) | (qrystr[4*i+1] << 8) | qrystr[4*i]
		}
		
		high = 0
		low = 0
		(0...qryx.size/2).each {|i|
			t = (0x0e79a9c1 * qryx[2*i])%0x7fffffff
			t = ((chlx[0] * (t+high)) + chlx[1])%0x7fffffff
			
			high = (qryx[2*i+1] + t)%0x7fffffff
			high = (chlx[2]*high + chlx[3])%0x7fffffff
			
			low = low + high + t
		}
		high,low = [(high + chlx[1]),(low + chlx[3])].map {|i|
			s = sprintf("%x",i%0x7fffffff)
			(s[6,2] + s[4,2] + s[2,2] + s[0,2]).to_i(16)
		}
		key64 = (high << 32) | low
		
		hash = sprintf("%016x%016x",md5[0,16].to_i(16)^key64,md5[16,16].to_i(16)^key64)
		return hash
	end
end
