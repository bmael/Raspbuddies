require 'rubygems'
require 'backports'
require 'bud'
require_relative 'raspbuddies_protocol'
require_relative 'broadcast/CausalBroadcast'
require 'socket'

class RaspbuddiesServer
  include Bud
  include RaspbuddiesProtocol
  
  bootstrap do
	@ca = CausalAgent.new("T0" , 
	                      :ext_ip => ip,
	                      :ext_port => port)
	@ca.run_bg
	@ca.initProcess
	
  end
  
  bloom do
    nodelist <= connect { |c| [c.client, c.id] } # Store new client persistently
	
	# send new client on channel new_client to all clients
    new_client <~ (nodelist * nodelist).pairs { |m,n| [n.key, m.values]} 
	stdio <~ nodelist { |c| [["New client : #{c.key} #{c.val}"]]}
	
# 	mcast <~ (mcast * nodelist).pairs { |m,n| [n.key, m.val] } # have to use broadcast cf M2 project

  end
  
  def stopProcess
	@ca.stop
  end
  
end

# ruby command-line wrangling
addr = ARGV.first ? ARGV.first : RaspbuddiesProtocol::DEFAULT_ADDR
ip, port = addr.split(":")

puts "------------------------------------------"
puts "                Run server"
puts "  Server address: #{ip}:#{port}"
# puts "  Private ip : #{Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.ip_address}"
puts "------------------------------------------"
program = RaspbuddiesServer.new(:ip => ip, :port => port.to_i)
program.run_fg

# CTRL + C pour interrompre
   interrupted = false
   
   trap("INT") { interrupted = true }
   
   while not interrupted
      sleep(0.5)
   end
   
program.stopProcess
   
puts "------------------------------------------"
puts "                   End"
puts "------------------------------------------"
