require 'xmpp4r'
require 'xmpp4r/jid'
require 'xmpp4r/presence'
require 'xmpp4r/roster'

module CanHasChat
  module Remote
    class ChatConnection < Jabber::Client
  
      include CanHasChat::Remote::Lockable
  
      def initialize(*opts)
        self.refresh_age
        @q_messages = []
        @q_messages.extend CanHasChat::Remote::Lockable
        super

        self.add_message_callback do |msg|
          @q_messages.synchronize_with do |list|
            self.refresh_age
            list << make_message("MESSAGE",
                                    msg.from.node,
                                    transport_for_domain(msg.from.domain),
                                    msg.body)
          end
        end
        self.add_presence_callback do |pres|
          @q_messages.synchronize_with do |list|
            unless pres.type == :error
              show = (pres.show) ? pres.show.to_s : "available"
              list << make_message("PRESENCE",
                                      pres.from.node,
                                      transport_for_domain(pres.from.domain),
                                      show)
            end
          end
        end
        self.add_iq_callback do |iq|
          @q_messages.synchronize_with do |list|
            if iq.type == :error
              list << make_message("ERROR",
                                      iq.from.node,
                                      transport_for_domain(iq.from.domain),
                                      iq.error.error, 
                                      :code => iq.error.code)
            end
          end
        end
      end
      
      def known_transports=(transports)
        @transport_lookup = transports
      end
      
      def transport_for_domain(domain)
        unless @transport_lookup.nil?
          key, value = @transport_lookup.find{ |k,v| v==domain }
          return key
        end
      end
      
      
      def make_message(type, from, domain, msg, extra={})
        {
          "time" => Time.now.to_i,
          "type" => type,
          "from" => from,
          "domain" => domain,
          "message" => msg
        }.merge(extra)
      end
  
      def age_in_seconds()
        return Time.now.to_i - @last_used_at
      end
  
      def does_limit_expire?(limit)
        return self.age_in_seconds <= limit
      end
  
      def refresh_age()
        puts "Refreshing age"
        @last_used_at = Time.now.to_i
      end
  
      def report_presence_to_transport(statusmsg, transport=nil, show=:chat)
        pres = Jabber::Presence.new
        pres.to = Jabber::JID.new(transport) unless transport.nil?
        pres.show = show
        pres.status = statusmsg
        self.send(pres)
        if transport.nil? && @roster.nil?
          @roster = Jabber::Roster::Helper.new(self)
          @roster.add_query_callback do |query|
            @q_messages.synchronize_with do |list|
              roster = {}
              @roster.items.each do  |key, value|
                transport = transport_for_domain(key.domain)
                roster[transport] ||= []
                roster[transport] << key.node unless key.node.nil?
              end
              list << make_message("ROSTER",
                                      "",
                                      "",
                                      roster)
            end
          end
        end
      end

  
      def queued_messages
        @q_messages
      end
      
      def roster()
        if @roster
          altered = @roster.items.collect { |jid, rosteritem| [jid.node, transport_for_domain(jid.domain)]}
          ros = {}
          altered.each do |nick, domain|
            ros[domain] ||= []
            ros[domain] << nick
          end
          return ros
        end
      end
  
      def empty_queue_of_all_messages(from=nil)
        unless from.nil?
          messages = @q_messages.find_all do |entry|
            "#{nick}@#{domain}"== entry["from"]
          end
          @q_messages.synchronize_with do |list|
            messages.each do |msg|
              @q_messages.delete_if { |itm| itm == msg }
            end
          end
      
          return messages
        else
          messages = Array.new(@q_messages)
          @q_messages.synchronize_with do |list|
            @q_messages.clear
          end
          return messages
        end
      end
  
      def register_to_transport(username, password, transport)
        reg = Jabber::Iq.new_register(username, password)
        reg.to = transport
        self.send(reg)
      end
  
      def self.oldest(list_of_connections)
        oldest = list_of_connections.first
        list_of_connections.each do |conn|
          if conn.age_in_seconds > oldest.age_in_seconds
            oldest = conn
          end
        end
      end
    end
  end
end