require 'rubygems'
require 'bud'
require 'backports'	
require_relative './raspbuddies_protocol'
require_relative './delivery/QCDelivery'
require_relative './lattice/LQVC'
require_relative './HashModule'

class Raspbuddies
  include Bud
  include RaspbuddiesProtocol
  include QCDelivery
  include HashFunctions
   
  state do
    interface input, :i_send, [:ident] => [:payload]
  end
  
  def initialize(id, server, opts={})
    @id = id
    @server = server
	@cpt = 0
    super opts
  end
  
  bootstrap do	
	@entries = hashKey(ip_port)
    connect <~ [[@server, ip_port, @id]]
	puts "Entries : #{@entries}"
  end
  
  ############################################################################
  ##								BLOOM LOOP								##
  ############################################################################
  
  # Receive a message
  bloom :rcv do 
	stdio <~ chn { |m| [["LOG received message #{logIntoFile(m.payload)}" ]]} # don't log if we are the msg sender
	stdio <~ buf_chosen { |p| [[" ploploplop #{p}"]]}
  end 
  
  bloom :snd do
	pipe_in <=(i_send * private_members).pairs{ |i,n|  [n.ident, ip_port, i.ident, i.payload] }
	stdio <~ i_send {|i| [["I_SEND : #{i}"]]}
  end
  
  # New clients detected by central server
  bloom :update_nodelist do
	private_members <= new_client {|c| addMember(c[1][0], c[1][1]) }
	stdio <~ new_client { displayPrivateMembers }
  end
   
  ###########################################################################
  ##							RUBY METHODS								 ##
  ###########################################################################
  
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
  
  def bcast
	  @cpt += 1
	  stdio <~ [["Sending a msg..."]]
	  i_send <+ [[ ip_port << @cpt.to_s, "plop"]]	  
	  sleep(1)
  end
  
  # Log a message into the file log.
  #TODO buffer for msg before log it
  def logIntoFile(msg)
    File.open("log/log" << ip_port, 'a') {|f| f.write(msg) 
				f.write("\n")  }
    return  msg 	
  end
  
  def stopProcess
	stop
  end
  
end

if(ARGV.length < 1)
  puts "Client must be launch with ARGV[0]:id"
else
  server = (ARGV.length == 3) ? ARGV[2] : RaspbuddiesProtocol::DEFAULT_ADDR
	  

  puts "------------------------------------------"
  puts "                Run Client"
  puts "  Server address: #{server}"
  puts "------------------------------------------"

  program = Raspbuddies.new(ARGV[0], server, :stdin => $stdin )

  program.run_bg

	nbMessage = 10 
	nbMessageReceived = 0
	
	sleep 2
	
	while nbMessage!=0 do
	  program.sync_do{
		  program.bcast
	  }
	  nbMessage -= 1
	end
	
	sleep 10

  puts "------------------------------------------"
  puts "                   End"
  puts "------------------------------------------"
  program.stopProcess
end



