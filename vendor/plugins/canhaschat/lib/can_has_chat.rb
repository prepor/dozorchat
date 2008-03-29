# This plugin adds Jabber server communication to your Rails app.  It 
# relies on the XMPP4R (http://home.gna.org/xmpp4r/) gem.   Install this 
# plugin into your vendor/plugins folder and configure config/chat_server.yml
# to reflect your particular Jabber server configuration.
#
# More information is available in the plugin's README.
#
#
# Author:: Indianapolis Star
# 
# This is the base module that is used to extend ActiveRecord::Base
# (as well as anything else that you'd like to add can_has_chat 
# functionality to)
#
require 'drb'
module CanHasChat
  module Base  
    def self.included(base) # :nodoc:
      base.extend ActMethods
    end

    #:nodoc:
    module ActMethods
      #
      # can_has_chat takes the following options:
      # namespace:: [String] Used to create a unique hash for the chats used in your application. (the hash is used as the JID resource identifier)
      # log_chats:: [Boolean] Not implemented yet
      # user_attribute:: [Symbol] Symbol for the method that returns the Jabber username of the object
      # transports:: [Hash] A Hash that contains information regarding which methods supply transport credentials for this object
      # The transports hash must take the form { :transport_name => :username_method }, or { :transport_name => [:username_method, :password_method] }
      #
      def can_has_chat(options={})    
        extend CanHasChat::Base::ClassMethods
        include CanHasChat::Base::InstanceMethods
        @can_has_chat_options = {
          :transports => nil,
          :user_attribute => nil,
          :log_chats => false,
          :namespace => "canhaschat",
          :config_file => File.join(RAILS_ROOT, "config/chat_server.yml")
        }.merge(options)
        config_path = @can_has_chat_options[:config_file]
        evaluated_config = ERB.new(File.read(config_path)).result
        yaml_config = YAML.load(evaluated_config)
        @can_has_chat_server_config = yaml_config[RAILS_ENV || "development"]
        @can_has_chat_server = DRbObject.new(nil, @can_has_chat_server_config["socket"])
      end
      
      #:nodoc:
      def can_has_chat_options
        return @can_has_chat_options
      end

      #:nodoc:      
      def can_has_chat_server
        return @can_has_chat_server
      end

      #:nodoc:
      def can_has_chat_server_config
        return @can_has_chat_server_config
      end
      
    end
  end
end