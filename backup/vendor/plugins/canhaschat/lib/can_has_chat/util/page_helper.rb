module CanHasChat
  module Util
    module PageHelper
      def wait_for_messages(options={})
        url = escape_javascript((options[:url]) ? url_for(options[:url]) : "")
        polling = (options[:polling] || false)
        frequency = (options[:frequency] || 5)
        # TOOD
        # not doing anything with this atm
        from = escape_javascript(options[:from] || nil)
        out = javascript_include_tag "can_has_chat"
        out += <<-EOJS
          <script type="text/javascript">
            var _canhaschat_ = CanHasChat.getInstance("#{url}", #{polling}, #{frequency});
            _canhaschat_.init();
          </script>
        EOJS
        return out
      end

      def for_new_messages(&block)         
        for_update_block(:message, &block)
      end

      def for_roster(&block)
        for_update_block(:roster, &block)
      end

      def for_presence_updates(&block)
        for_update_block(:presence, &block)
      end

      def call_for_presence_updates(js_func)
        call_for_js_func(:presence, js_func)
      end

      def call_for_roster(js_func)
        call_for_js_func(:roster, js_func)
      end

      def call_for_new_messages(js_func)
        call_for_js_func(:message, js_func)
      end

      private

      def for_update_block(type, &block)
        output = capture(CanHasChat::Util::JavascriptMessage.new, &block)
        func = CanHasChat::Util::JavascriptHelper::generateFunctionBlock(type, 
                                                        escape_javascript(output))
        concat(func, block.binding)
      end

      def call_for_js_func(type, func)
        type = type.to_s.capitalize
        return <<-EOJS
          <script type="text/javascript">
            Event.observe(window, "load", function(){
              var inst = CanHasChat.getInstance(null,null,null);
              inst.add#{type}Callback(#{func});
            });
          </script>
        EOJS
      end
    end
  end
end