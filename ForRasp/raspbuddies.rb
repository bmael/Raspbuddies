require 'rubygems'
require 'bud'
require 'backports'	
require_relative './raspbuddies_protocol'
require_relative './broadcast/CausalBroadcast'
require 'socket'

class Raspbuddies
  include Bud
  include RaspbuddiesProtocol
   
  def initialize(id, server, opts={})
    @id = id
    @server = server

    super opts
  end
  
  bootstrap do
	ipC, portC = ip_port.split(":")
	@ca = CausalAgent.new("T#{@id}" , 
	                      :ext_ip => ipC,
	                      :ext_port => portC.to_i)
	@ca.run_bg
	@ca.initProcess
	
	ipS, portS = @server.split(":")
	
    connect <~ [[@server, ip_port, @id]]
	
	@ca.sync_do {
	  @ca.pipe_join <+ [[@server]]
	}
	puts "Sleepinf for 5 seconds to wait others clients..."
	sleep(5)
  end
  
  ############################################################################
  ##								BLOOM LOOP								##
  ############################################################################
  
  # Receive a message
  bloom :rcv do 
	stdio <~ mcast { |m| [["LOG received message #{logIntoFile(m.val)}" ]] if m.val[0]!=ip_port} # don't log if we are the msg sender
	stdio <~ mcast { |m| [["Receiving my message #{m.val}"]] if m.val[0]==ip_port} # advise that you received your message

  end
  
  # New clients detected by central server
  bloom :update_nodelist do
# 	stdio <~ new_client { |c| [["new client", c.val]]}
# 	stdio <~ nodelist{ |c| [["nodelist", c.val]]}
  end
   
  ###########################################################################
  ##							RUBY METHODS								 ##
  ###########################################################################
   # Log a message into the file log.
  #TODO buffer for msg before log it
  def logIntoFile(msg)
    File.open("log/log" << ip_port, 'a') {|f| f.write(msg) 
				f.write("\n")  }
    return  msg 	
  end
    
  #method to send a message
  def sendMsg() 
	      var = Bud::MapLattice.new({0=>Bud::MaxLattice.new(0),1=>Bud::MaxLattice.new(0),2=>Bud::MaxLattice.new(1),3=>Bud::MaxLattice.new(0),
				4=>Bud::MaxLattice.new(0),5=>Bud::MaxLattice.new(1),6=>Bud::MaxLattice.new(0),7=>Bud::MaxLattice.new(0),
				8=>Bud::MaxLattice.new(0),9=>Bud::MaxLattice.new(4),10=>Bud::MaxLattice.new(0),11=>Bud::MaxLattice.new(0),
				12=>Bud::MaxLattice.new(0),13=>Bud::MaxLattice.new(5),14=>Bud::MaxLattice.new(0),15=>Bud::MaxLattice.new(1),
				16=>Bud::MaxLattice.new(0)})
		  @ca.sync_do{
			
	  @ca.bcast_send <+ [[[@server, [ip_port, "", "Hello from " << ip_port, "" ]], [3, var]]]
			}
# 	  @ca.inclock <+ [[0,var]] # Throws an exception like undifined method ??
# 	  mcast <~ [[@server, [ip_port, "", "Hello from " << ip_port, "" ]]]
	  stdio <~ [["Sending a message..."]]
  end
  
  def sendMsg2(wait_time)
	return [@server, [ip_port, "", "Hello from " << ip_port, "" ]]
  end
  
  def stopProcess
	@ca.stop
  end
    
end


server = (ARGV.length == 2) ? ARGV[1] : RaspbuddiesProtocol::DEFAULT_ADDR
	

puts "------------------------------------------"
puts "                Run Client"
puts "  Server address: #{server}"
# # puts "  Private ip : #{Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.ip_address}"
puts "------------------------------------------"

program = Raspbuddies.new(ARGV[0], server, :stdin => $stdin )

program.run_bg

  nbMessage = 10 
  nbMessageReceived = 0
  
  sleep 2
  
  while nbMessage!=0 do
	program.sync_do{
		program.sendMsg()
	}
	nbMessage -= 1
  end
  
  sleep 10
   
program.stopProcess
   
puts "------------------------------------------"
puts "                   End"
puts "------------------------------------------"
program.stop



