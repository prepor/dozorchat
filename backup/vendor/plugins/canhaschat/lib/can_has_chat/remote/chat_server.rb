require 'digest'
require 'drb'
require 'logger'
require 'thread'
require 'xmpp4r'
require 'xmpp4r/jid'
require 'xmpp4r/roster'

module CanHasChat
  module Remote
    class NoValidRecipient < StandardError; end
    class NoNamespace < StandardError; end
    class NoValidSender < StandardError; end
    class NoValidUsername < StandardError; end
    class NoValidPassword < StandardError; end
    class NoValidTransport < StandardError; end
    class NoTransportNamed < StandardError; end
    class NoSuchConfigFile < StandardError; end
    class NoMessage < StandardError; end
    class MustSupplyPassword < StandardError; end 
    class NoTransportByThatName < StandardError; end
    class NoChatID < StandardError; end
    class NoChatWithThatID < StandardError; end
    
    class ChatServer 
      include CanHasChat::Remote::ChatDaemon
      
      def self.default_config()
        {
          "socket"  => "drbunix://tmp/chat_server.sock",
          "max_connections" => 10,
          "chat_timeout" => 300,
          "cleanup_interval" => 180,
          "jabber_server" => "localhost",
          "jabber_realm" => "myjabber",
          "use_anonymous_jabber" => true,
          "pid_file" => "tmp/chat_server.pid",
          "log_file" => "log/chat_server.log",
          "log_level" => "ERROR",
          "use_mongrel_handler" => false,
          "transports" => {
            "aim" => nil,
            "yahoo" => nil,
            "icq" => nil,
            "google" => nil
          }
        }
      end
      def self.start(options={})
        config = self.default_config().merge(options)
        cs = ChatServer.new(config)
        puts "Starting chat server"
        cs.platform_daemon do
          DRb.start_service(config["socket"], cs.run)
          DRb.thread.join
        end
      end
      
      def self.stop(options={})
        config = self.default_config().merge(options)
        ChatServer.new(config).stop
      end
      
      def self.fg(options={})
        config = self.default_config().merge(options)
        DRb.start_service(config["socket"], ChatServer.new(config, true).run)
        DRb.thread.join
      end
      
      def self.restart(options={})
        self.stop(options)
        self.start(options)
      end
  
      def initialize(config = {}, foreground=nil)
          @config = config
          @connections = {}
          @connections.extend CanHasChat::Remote::Lockable
          @connection_jid = ((@config["use_anonymous_jabber"]) ? 
                              "#{@config["jabber_realm"]}" :
                              nil)
          if foreground
            @logger = Logger.new(STDOUT)
          elsif config["log_file"]
            @logger = Logger.new(config["log_file"])
          else
            @logger = Logger.new(STDERR)
          end
          if config["log_level"]
            level = config["log_level"].upcase
          else
            level = "ERROR"
          end
          @logger.level = Logger::const_get(level)
          info "Chat server initialized"
      end
      
      def run()
        debug "Starting server operations"
        cleanup_interval = @config["cleanup_interval"]
        chat_timeout = @config["chat_timeout"]
        @cleanup_thread = Thread.start do
          while true
            debug "Attempting to synchronize with connection array"
            @connections.synchronize_with do |list|
              list.each do |key, conn|
                debug "Checking connection with an age of #{conn.age_in_seconds} against timeout #{chat_timeout}"
                if conn.age_in_seconds >= chat_timeout
                  debug "Attempting to synchronize with connection"
                  conn.synchronize_with do |c|
                    c.close
                    list.delete key
                    info "Stale chat reaped, maximum age exceeded"
                  end
                end
              end
            end
            debug "Sleeping reaper thread"
            sleep(cleanup_interval)
          end
        end
        return self
      end
      
      def info(msg)
        @logger.info msg
      end
      
      def error(msg)
        @logger.error msg
      end
      
      def debug(msg)
        @logger.debug msg
      end
      
      def warn(msg)
        @logger.warn msg
      end
  
      def check_for_messages(options={})
        unless options[:id]
          error "No chat id was provided "
          raise NoChatID unless options[:id]
        end
        
        debug "Attempting to synchronize with connection for chat id #{options[:id]}"
        begin
          get_connection_for(options[:id]).synchronize_with do |conn|
            sender_jid = get_user(options[:from], options[:transport]) if options[:from]
            return conn.empty_queue_of_all_messages(sender_jid)
          end
        rescue
          return -1
        end
      end
  
      def start_chat(options={})
        unless options[:user] && !@config["use_anonymous_jabber"]
          error "No valid sender received for transport registration"
          raise NoValidSender
        end
        unless options[:namespace]
          error "No namespace received for transport registration"
          raise NoNamespace
        end
        debug "Attempting to synchronize with connection for #{options[:user]}, #{options[:namespace]}"
        resource = nil
        make_connection_for(options[:user], 
                            options[:namespace],
                            options[:password]).synchronize_with do |conn|
          if options[:transports]
            options[:transports].each do |transport, credentials|
              debug "Registering at #{transport}"
              username, password = credentials
              conn.register_to_transport(username,
                                          password,
                                          get_transport(transport))
            end

          end
          debug "Attempting to send presence notification to server"
          conn.report_presence_to_transport(options[:status] || "")
          if options[:transports]
            options[:transports].each do |transport, credentials|
              debug "Attempting to send presence notification to transport #{transport}"
              conn.report_presence_to_transport(options[:status] || "", get_transport(transport))
            end
          end
          resource = conn.jid.resource
        end
        return resource
      end
      
      def end_chat(options={})
        unless options[:id]
          error "No chat id was provided"
          raise NoChatID 
        end
        conn = get_connection_for(options[:id])
        @connections.synchronize_with do |list|
          list.delete options[:id]
        end
        conn.synchronize_with do |c|
          c.close
        end
        return nil
      end
      
      def roster(options={})
        unless options[:id]
          error "No chat id was provided"
          raise NoChatID 
        end
        return get_connection_for(options[:id]).roster
      end
  
      def send_message(options={})
        unless options[:to]
          error "No valid recipient received for attempt to send message"
          raise NoValidRecipient 
        end
        unless options[:message]
          error "No message specified in attempt to send message (seriously, what?)"
          raise NoMessage 
        end
        unless options[:id]
          error "No chat id was provided"
          raise NoChatID 
        end
        jid = get_jid(options[:to], options[:transport])
        debug "Attempting to send message to #{jid.to_s}"
        message = options[:message]
        debug "Attempting to synchronize with connection with id #{options[:id]}"
        get_connection_for(options[:id]).synchronize_with do |conn|
          debug "Sending message for chat #{options[:id]}"
          conn.send Jabber::Message.new(
                              jid,
                              message)
          conn.refresh_age
        end
        return message
      end
  
      def chat_exists?(chatid)
        return !@connections[chatid].nil?
      end

      private
      
      def generate_chat_id(user, namespace)
        ts = Time.now.to_i.to_s
        id = Digest::SHA1.hexdigest("#{user}-#{namespace}---#{ts}")
        return id
      end
    
      def get_transport(tid)
        unless tid.nil?
          transport =  @config["transports"][tid.to_s.downcase]
          if transport.nil?
            error "Attempted to get transport #{tid}, no such transport exists"
            raise NoTransportByThatName
          end
        else
          transport = @config["jabber_realm"]
        end
        return transport
      end
  
      def get_user(user, transport=nil)
        return "#{user}@#{get_transport(transport)}"
      end
  
      def get_jid(user, transport=nil)
        return Jabber::JID.new(get_user(user, transport))
      end
      
      def get_connection_for(id)
        debug "Looking for connection with resource #{id}"
        conn = @connections[id]
        @connections.synchronize_with do |list|
          if conn
            debug "Found connection"
          end
        end
        if conn.nil?
          error "Could not find chat with specified id"
          raise NoChatWithThatID
        end
        return conn
      end
      
      def make_connection_for(user, namespace, password=nil)
        resource = generate_chat_id(user,  namespace)
        debug "Getting connection for resource #{resource}"
        connection_jid = @connection_jid || get_user(user)
        debug "Attempting to synchronize with connection list"
        @connections.synchronize_with do |list|
          unless list[resource]
            if list.size >= @config["max_connections"]
              debug "Connection maximum reached, attempting to synchronize with oldest connection in order to reap"
              ChatConnection.oldest(list).synchronize_with do |connection|
                connection.close
                list.delete connection
                info "Stale connection reaped to make room for new connection (max connections reached)"
              end
            end
            connection = ChatConnection.new "#{connection_jid}/#{resource}"
            connection.known_transports = @config["transports"]
            connection.connect @config["jabber_server"]
            if @config["use_anonymous_jabber"] 
              info "Attempting to connect using anonymous sasl authentication"
              connection.auth_anonymous_sasl
            else
              if password.nil?
                warn "No password supplied and no connection exists for #{user}, #{namespace} - catch MustSupplyPassword to prevent this from reaching the user"
                raise MustSupplyPassword
              end
              connection.auth password
            end
            list[resource] = connection
          else
            list[resource].synchronize_with do |connection|
              debug "Refreshing age for connection #{resource}"
              connection.refresh_age
              connection.report_presence_to_transport("")
            end
          end
          return list[resource]
        end
      end
    end
  end
end