module CanHasChat
  module Util
    class JavascriptMessage
      MESSAGE_TOKEN = "<canhaschatmessage>"
      FROM_TOKEN = "<canhaschatfrom>"
      TIMESTAMP_TOKEN = "<canhaschattimestamp>"
      NETWORK_TOKEN = "<canhaschatnetwork>"
      
      def message
        return MESSAGE_TOKEN
      end
      
      def from
        return FROM_TOKEN
      end
      
      def timestamp
        return TIMESTAMP_TOKEN
      end
      
      def network
        return NETWORK_TOKEN
      end
    end
  end
end