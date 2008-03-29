require 'rubygems'
require 'json'

require 'drb'
require 'erb'
require 'yaml'

# basic form of this file
# taken from:
# http://adam.blogs.bitscribe.net/

class PushHandler < Mongrel::HttpHandler
   def initialize
     config_file = File.read("config/chat_server.yml")
     evaluated = YAML.load(ERB.new(config_file).result)
     @config = evaluated[ENV["RAILS_ENV"] || "development"]
     @server = DRbObject.new(nil, @config["socket"])
     @keepalive_secs = (@config["mongrel_keepalive"]) ? @config["mongrel_keepalive"].to_i : 30
   end

   def process(request, response)
     params = Mongrel::HttpRequest.query_parse(request.params["QUERY_STRING"])
     chat_id = params["chat_id"]
     from = params["from"]
     transport = params["transport"]
     messages = []
     request_start = Time.now
      begin 
        while messages.empty?
          messages = wait_for_messages(chat_id, from, transport)
          if (Time.now-request_start)<@keepalive_secs
            sleep(0.5)
          else
            break
          end
        end
        response.start(200) do |head, out|
          head["Content-type"] = "application/json"
          out.write messages.to_json
        end
      rescue
        response.start(500) do |head, out|
          head["Content-type"] = "text/plain"
          out.write "An error ocurred when fetching messages"
        end
      end
   end
   
   def wait_for_messages(chatid, from, transport)
     messages =nil
     begin
       messages = @server.check_for_messages(:id => chatid,
                                            :from => from,
                                            :transport => transport)
     rescue
       puts $!.to_s
       raise
     end
     return messages
   end
end

uri "/<%= controller_file_name %>/push", :handler => PushHandler.new, :in_front => true