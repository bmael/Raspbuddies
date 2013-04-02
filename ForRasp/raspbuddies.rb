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
# 	@mc = MC.new
# 	startMC
# 	
    connect <~ [[@server, ip_port, @id]]
	
  end
  
  ############################################################################
  ##								BLOOM LOOP								##
  ############################################################################
  
  # Receive a message
  bloom :rcv do 
	stdio <~ mcast{ |m| [["LOG received message #{logIntoFile(m.val)}" ]] if m.val[0]!=ip_port} # don't log if we are the msg sender
	stdio <~ mcast { |m| [["Receiving my message #{m.val}"]] if m.val[0]==ip_port} # advise that you received your message
# 	mcast <~ (mcast * private_members).pairs { |m,n| [n.ident, m.val] }
# 	mcast <~ (mcast * private_members).pairs { |m,n| [n.host, m.val] }
  end
  
  bloom :snd do
		mcast <~ (my_msg * private_members).pairs { |m,n| [n.ident, m.val] }
  end
  
  # New clients detected by central server
  bloom :update_nodelist do
# 	stdio <~ new_client { |c| [["new client #{addMember(c[1], c[0])}"]] }
	private_members <= new_client {|c| addMember(c[1][0], c[1][1]) }
	stdio <~ new_client { displayPrivateMembers }
# 	puts "There are #{@mc.num_members.inspected} clients"
# 	stdio <~ private_members{ |c| [["private_members #{c.val}"]]}
  end
   
  ###########################################################################
  ##							RUBY METHODS								 ##
  ###########################################################################
  def startMC
# 	@mc.run_bg
  end 
  
  def addMember(addr, id)
# 	@mc.sync_do{	@mc.add_member <+ [[id, addr]] }
# 	puts "There are #{@mc.num_members.inspected} clients"
# 	@mc.sync_do{ @mc.mcast_send <+ [[1, 'foobar']] }
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
  
  # Log a message into the file log.
  #TODO buffer for msg before log it
  def logIntoFile(msg)
    File.open("log/log" << ip_port, 'a') {|f| f.write(msg) 
				f.write("\n")  }
    return  msg 	
  end
    
  #method to send a message
  def sendMsg() 
	  my_msg <~ [[@server, [ip_port, "", "Hello from " << ip_port, "" ]]]
# 	  mcast_send <+ [[ip_port, "cc"]]
	  stdio <~ [["Sending a message..."]]
  end
  
  def sendMsg2(wait_time)
	return [@server, [ip_port, "", "Hello from " << ip_port, "" ]]
  end
  
  def stopProcess
# 	@mc.stop
	stop
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
program.stopProcess



