require 'rubygems'
require 'xmpp4r/client'
include Jabber

client = Client.new(JID::new("dozorchat@gmail.com"))
client.connect
client.auth("hzdsed12")
client.send(Presence.new.set_type(:available))

msg = Message::new("rudenkoco@gmail.com", "Hello… John?")
msg.type=:chat
client.send(msg)
