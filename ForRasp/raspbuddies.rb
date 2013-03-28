require 'rubygems'
require 'bud'
require 'backports'	
require_relative './raspbuddies_protocol'

class Raspbuddies
  include Bud
  include RaspbuddiesProtocol
   
  def initialize(id, server, opts={})
    @id = id
    @server = server

    super opts
  end
  
  bootstrap do
    connect <~ [[@server, ip_port, @id]]
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
	     
# 	  @ca.inclock <+ [[0,var]] # Throws an exception like undifined method ??
# 	  mcast <~ [[@server, [ip_port, "", "Hello from " << ip_port, "" ]]]
	  stdio <~ [["Sending a message..."]]
  end
  
  def sendMsg2(wait_time)
	return [@server, [ip_port, "", "Hello from " << ip_port, "" ]]
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
   
   
puts "------------------------------------------"
puts "                   End"
puts "------------------------------------------"
program.stop



