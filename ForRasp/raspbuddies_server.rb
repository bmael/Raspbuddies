require 'rubygems'
require 'backports'
require 'bud'

require_relative './raspbuddies_protocol'


class RaspbuddiesServer
  include Bud
  include RaspbuddiesProtocol  
  
  bootstrap do
	@mc = MC.new
	startMC
	
  end
  
  bloom do
    nodelist <= connect { |c|  addMember(c.id, c.client) } # Store new client persistently
	
	# send new client on channel new_client to all clients
    new_client <~ (nodelist * nodelist).pairs { |m,n| [n.key, m.values]}
# 	stdio <~ nodelist { |c| [["New client : #{c.key} #{c.val}"]]}
	
	mcast <~ (mcast * nodelist).pairs { |m,n| [n.key, m.val] } # have to use broadcast MC

  end
  
  def addMember(id, addr)
	@mc.sync_do{	@mc.add_member <+ [[id, addr]] }
	puts "There are #{@mc.num_members.inspected} clients"
# 	@mc.sync_do{ @mc.mcast_send <+ [[1, 'foobar']] }
	return [addr, id]
  end
  
  def startMC
	@mc.run_bg
  end
  
  def stopProcess
	@mc.stop
	stop
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
