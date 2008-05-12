## Copyright (c) 2006 Paul Vaillant, All Rights Reserved

require 'socket'

module Net; module IM; class TOC2

	VERSION = "TIC:Net-IM-TOC2"
	ROASTER = "Tic/Toc"

	def initialize(roster, user, pwd, opts = {})
		@options = {
			:login_host => "login.oscar.aol.com",
			:login_port => 5190,
			:toc_host => "aimexpress.oscar.aol.com",
			:toc_port => 5190,
			:language => "english",
			:user_info => "Using ruby Net::IM"
		}.merge(opts)
		
		@roster = roster
		@user = user
		@pwd = pwd
		@tid = rand(1000)
		
		login()
		
		@poll = Thread.new {
			loop {
				IO.select([@fd],nil,nil)
				msg = recv()
				if(msg =~ /^IM_IN2:/i)
					## handleIM(msg)
					debug "HANDLE_MSG: #{msg}"
					cmd,from,a,b,msg = msg.split(/:/,5)
				elsif(msg =~ /^ERROR:/i)
					## handleError
					debug "HANDLE_ERR: #{msg}"
					cmd,msg = msg.split(/:/,2)
				else
					## handleUnknown
					debug "HANDLE_UNK: #{msg}"
				end if msg
				sleep 0.01
			}
		}
	end
	
	def debug(*a)
		STDERR.puts a.inspect
	end
	
	################ BEGIN REQUIRED FUNCTIONS ##################
	def nick=(new_nick)
	end
	
	## TBI def info=(new_info)
	
	def status=(new_status)
	end
	
	## TBI def privacy=(new_privacy)
	
	def add_user(user)
	end
	
	def allow_user(user)
	end
	
	def block_user(user)
	end
	
	## TBI def update_user(user)
	
	def remove_user(user)
	end
	
	def add_group(group)
	end
	
	def add_user_to_group(user, group)
	end
	
	def remove_user_from_group(user, group)
	end
	
	## TBI def update_group(group)
	
	def remove_group(group)
	end
	
	def sendmsg(user,msg)
		encoded_user_name = user.name.downcase.gsub(/\s+/,'')
		encoded_msg = msg.gsub(/\r/,'<br>').gsub(/[{}\\"]/,'\\\1')
		send("toc2_send_im #{encoded_user_name} \"#{encoded_msg}\"")
	end
	
	def disconnect
	end
	
	############### END OF REQUIRED FUNCTIONS ##################
	
	def send(msg,type=2) ## type: 1 SIGNON, 2 DATA
		@tid += 1
		msg << [].pack("x") if type == 2
		buf = [0x2a,type,@tid,msg.size,msg].pack("C2nna#{msg.size}")
		debug ["SEND",buf]
		@fd.write(buf)
		@fd.flush
		return nil
	end
	
	def recv
		c = @fd.read(1)
		if(c != '*')
			debug ["UNEXPECTED",c]
			return nil
		else
			@fd.read(3) ## type, seq = unpack('Cn')
			len = (@fd.read(1)[0]*0x100) + @fd.read(1)[0] # or unpack('n')
			msg = @fd.read(len)
			debug ["RECV",msg]
			return msg
		end
	end
	
	private
	def login()
		@fd = TCPSocket.new(@options[:toc_host],@options[:toc_port])
		@fd.write("FLAPON\r\n\r\n")
		recv
		## send flap signon
		send([1,1,@user.size,@user].pack("Nnna#{@user.size}"),1)
		
		send("toc2_login #{@options[:login_host]} #{@options[:login_port]} #{@user} #{roast_password(@pwd)} #{@options[:language]} \"#{VERSION}\" 160 US \"\" \"\" 3 0 30303 -kentucky -utf8 #{login_code(@user,@pwd)}")
		resp = recv ## should be SIGN_ON:TOC2.0
		
		raise AuthenticationError, resp if resp =~ /^ERROR/
		
		#send("toc_add_buddy #{@user}")
		send("toc_init_done")
		#send("toc_set_caps 09461343-4C7F-11D1-8222-444553540000 09461348-4C7F-11D1-8222-444553540000")
		#send("toc_add_permit ")
		#send("toc_add_deny ")
		send("toc2_set_pdmode 1")
		send("toc_set_info \"#{@options[:user_info]}\"")
	end
	
	def login_code(user,pwd)
		return user[0]*pwd[0]*7696
		
		sn = user[0]-96
		pw = pwd[0]-96
		
		
		i = sn * 7696 + 738816
		j = i  * 746512
		k = j * pw
		return (k - i + j + 71665152)
	end
	
	def roast_password(pwd)
		rst = ['0x'] 
		rst << (0...pwd.length).map {|i|
			sprintf("%02x",ROASTER[i%ROASTER.size]^pwd[i])
		}
		return rst.join
	end

end; end; end