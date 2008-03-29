require 'rubygems'
require 'ruburple'
 Ruburple::init
 Ruburple::debug = true
 Ruburple::subscribe(:received_im_msg, (Proc.new do |a,b,c,d,e| puts "rcv im: #{a}, #{b}, #{c}, #{d}, #{e}" end))
 Ruburple::subscribe(:signed_on, (Proc.new do |a| puts "signed on: #{a}" end))
 # p = Ruburple::get_protocol("ICQ")
 # puts "gonna connect to #{p.id}, #{p.name}, #{p.version}, #{p.summary}, #{p.description}, #{p.author}, #{p.homepage}"
 # a = p.get_account("174677692", "hzdsed")
 # a.connect
 # a.connection.send_im("383592922", "some message")
 # a.connection.close
 
 p = Ruburple::get_protocol("XMPP")
  puts "gonna connect to #{p.id}, #{p.name}, #{p.version}, #{p.summary}, #{p.description}, #{p.author}, #{p.homepage}"
  a = p.get_account("dozorchat@gmail.com", "hzdsed12")
  a.connect
  a.connection.send_im("rudenkoco@gmail.com", "some message")
  a.connection.close