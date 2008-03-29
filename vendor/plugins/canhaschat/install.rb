require 'fileutils'

def install(file)
  puts "Installing: #{file}"
  target = File.join(File.dirname(__FILE__), '..', '..', '..', file)
  if File.exists?(target)
    puts "target #{target} already exists, skipping"
  else
    FileUtils.cp File.join(File.dirname(__FILE__), file), target
  end
end

install File.join( 'script', 'chat_server' )
install File.join( 'config', 'chat_server.yml' )
install File.join( 'public', 'javascripts', 'can_has_chat.js')

puts IO.read(File.join(File.dirname(__FILE__), 'README'))

