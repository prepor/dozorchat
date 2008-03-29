require 'drb'
require 'erb'
require 'optparse'
require 'yaml'


# some of the basic form of this file is taken
# from the acts_as_ferret drb server startup script

config_file = "config/chat_server.yml"
environment = ENV["RAILS_ENV"] || "development"
action = "start"
OptionParser.new do |opts|
  opts.banner = "Usage: chat_server [options] {start|stop|restart|fg}"
  
  opts.on("-d", "--debug", "Print XMPP4R debug messages (only in fg mode)") do |v|
    Jabber.debug = true
  end
  
  opts.on("-e", "--environment ENV", "Run in specific Rails environment") do |e|
    environment = e
  end

  action = opts.permute!(ARGV)
  (puts opts; exit(1)) unless action.size == 1

  action = action.first
  (puts opts; exit(1)) unless %w(start stop restart fg).include?(action)
end


ENV["RAILS_ENV"] = environment
require File.join(File.dirname(ENV["_"]), '../config/environment')

if File.exists? config_file
  config = YAML.load(ERB.new(File.read(config_file)).result)[environment]
  CanHasChat::Remote::ChatServer.send(action.to_sym, config)
else
  raise "NoSuchConfigFile"
end
