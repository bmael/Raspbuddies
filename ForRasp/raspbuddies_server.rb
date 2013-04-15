require 'rubygems'
require 'backports'
require 'bud'

require_relative './raspbuddies_protocol'


class RaspbuddiesServer
  include Bud
  include RaspbuddiesProtocol  
  
  bootstrap do

  end
  
  bloom do
    private_members <= connect { |c|  addMember(c.client, c.id) } # Store new client persistently
	stdio <~ private_members { displayPrivateMembers } #display the list of clients when there is a new connection
	# send new client on channel new_client to all clients
    new_client <~ (private_members * private_members).pairs { |m,n| [n.ident, m.values] }
  end
  
  def addMember(addr, id)
	return [addr, id]
  end
  
  def displayPrivateMembers()
	i=0;
	puts "\t --------------------------------"
	puts "\t |   Private members            |"
	puts "\t --------------------------------"
	private_members.each do |m|
	  i += 1
	  puts "\t | #{i} | #{m} |"
	end
	puts "\t -------------------------------"
  end
  
  def stopProcess
	stop
  end
  
end

# ruby command-line wrangling
addr = ARGV.first ? ARGV.first : RaspbuddiesProtocol::DEFAULT_ADDR
ip, port = addr.split(":")

puts "------------------------------------------"
puts "                Run server"
puts "  Server address: #{ip}:#{port}"
puts "------------------------------------------"
program = RaspbuddiesServer.new(:ip => ip, :port => port.to_i)
program.run_bg

# CTRL + C to stop
   interrupted = false
   
   trap("INT") { interrupted = true }
    
   while not interrupted
      sleep(0.5)
   end
   
program.stopProcess
   
puts "------------------------------------------"
puts "                   End"
puts "------------------------------------------"
