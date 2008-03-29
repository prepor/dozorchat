module CanHasChat
  module Util
    module JavascriptHelper
      
      def self.parseOutput(html)
        html.gsub!(/#{JavascriptMessage::MESSAGE_TOKEN}/, "\"+message+\"")
        html.gsub!(/#{JavascriptMessage::FROM_TOKEN}/, "\"+from+\"")
        html.gsub!(/#{JavascriptMessage::TIMESTAMP_TOKEN}/,"\"+timestamp+\"")
        html.gsub!(/#{JavascriptMessage::NETWORK_TOKEN}/, "\"+network+\"")
        return html
      end
      
      def self.generateFunctionBlock(type, escaped)
        html = self.parseOutput(escaped)
        type = type.to_s.capitalize
        addto = "_canhaschat_receptor_#{Time.now.to_i.to_s}"
        return <<-EOJSBLOCK
          <span id="#{addto}" style="display:none;"></span>
          <script type="text/javascript">
            Event.observe(window, "load", function(){
              var inst = CanHasChat.getInstance(null, null, null);
              var elm = $("#{addto}").parentNode;
              elm.removeChild($("#{addto}"));
              inst.add#{type}Callback(
                function(timestamp, from, message, network){
                  new Insertion.Bottom(elm, "#{html}");
                }
              );
            });
          </script>
        EOJSBLOCK
      end
      
    end
  end
end