# This module contains all the instance methods that will be added to the
# object that has can_has_chat invoked upon it.
module CanHasChat
  #:nodoc:
  module Base
    #:nodoc:
    module InstanceMethods
      #
      # Starts chat session with the dRuby server, or refreshes a chat
      # if one already exists
      #
      # password:: [String] The jabber password
      # transport_password:: [Hash] A hash of all the transport passwords to authenticate with, of the form { :transport_name => "transport_password" }
      # return:: [String] The Chat ID
      def start_chat(password=nil, transport_passwords={})
        klass = self.class
        transport_config = get_transports
        for transport, tpw in transport_passwords
          if transport_config[transport]
            transport_config[transport][1] = tpw
          end
        end
        return klass.can_has_chat_server.start_chat(:user => get_canhaschat_user,
                                              :namespace => klass.can_has_chat_options[:namespace],
                                              :transports => transport_config,
                                              :password => password)
      end
      
      #
      # Ends the chat specified by the given Chat ID
      #
      def end_chat(chatid)
        self.class.can_has_chat_server.end_chat(:id => chatid)
      end
  
      #
      # Sends a message to a contact, optionally in a non-Jabber transport
      #
      # chatid:: [String] The chat ID for the connection this message will be sent through
      # contact:: [String] The name of the contact to route the message to
      # message:: [String] The...uh...message
      # transport:: [String] Optional, the string name of the transport that hosts the recipient
      #
      def send_message_to(chatid, contact, message, transport=nil)
        return self.class.can_has_chat_server.send_message( :id => chatid,
                                                :to=>contact,
                                                :message=>message,
                                                :transport =>transport)
      end
      
      #
      # Checks whether a connection matching the given chat id exists
      # chatid:: [String] The chat to check for
      # return:: [Boolean] true or false
      def chat_exists?(chatid)
        return self.class.can_has_chat_server.chat_exists?(chatid)
      end
  
      #
      # Gets all messages for a given chat.  (NOTE that this does not mean
      # just chat messages, but all Presence, Roster Query, Iq Error and Chat
      # messages)
      #
      # chatid:: [String] The chat to retrieve messages from
      # contact:: [String] Optional, the name of the contact whose messages should be selectively received
      # transport:: [String] Optional, the name of the transport from which to take messages
      #
      # return:: [Array] Contains Hashes specifying the different message payloads.  
      def get_messages_from(chatid, contact=nil, transport=nil)
        return self.class.can_has_chat_server.check_for_messages(:id => chatid,
                                                            :from => contact,
                                                            :transport => transport)
      end
      
      #
      # Retrieves the roster for the user owning the chat specified by chatid.
      # NOTE that this method is unstable and may not always return a result.
      #
      # chatid:: [String] The chat from which to query for a roster.
      # 
      # return:: [Hash] A hash with keys representing the different available transports, and values that are arrays of users.
      def roster(chatid)
        return self.class.can_has_chat_server.roster(:id => chatid)
      end
      
      private
      
      def get_canhaschat_user()
        user = self.class.can_has_chat_options[:user_attribute]
        if user.is_a? Symbol
          return self.send user
        elsif user.is_a? String
          return user
        end
      end
      
      def get_transports()
        transports = self.class.can_has_chat_options[:transports]
        unless transports.nil?
          info = {}
          transports.each do |transport, val|
            if val.is_a? Symbol
              info[transport] = [self.send(val)]
            elsif val.is_a? Array
              raise "InvalidParametersForTransport" if val.size > 2
              if val.size>=1
                username = self.send(val[0])
              else
                username = self.send(transport)
              end
              if val.size==2
                password = self.send(val[1])
              end
              info[transport] = [username, password]
            end
          end
          return info
        else
          return {}
        end
      end
      
    end
    
  end
end