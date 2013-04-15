require 'rubygems'
require 'bud'
require 'backports'	
require_relative './raspbuddies_protocol'
require_relative './delivery/QCDelivery'
require_relative './lattice/LQVC'

class Raspbuddies
  include Bud
  include RaspbuddiesProtocol
  include QCDelivery
   
  
  state do
    interface input, :i_send, [:dst] => [:payload]
  end
  
  def initialize(id, k, server, opts={})
    @id = id
	@entries = k
    @server = server
	@qvc = {  0 => 0,
			  1 => 0,
			  2 => 0}	
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
	stdio <~ pipe_out
  end
  
  bloom :snd do
	mcast <~ (my_msg * private_members).pairs { |m,n| [n.ident, m.val] }
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
	private_members.each do |m|
	  my_msg <~ [[m.ident, [ip_port, [@qvc, @entries, @id], "Hello from " << ip_port, "" ]]]
	  stdio <~ my_msg {|i| [["cccccccccccccccccccccccc #{m.ident} | #{i[1][1]}"]]}
	  i_send <+ my_msg { |i| [ m.ident, i[1][1] ]}
	  
	  pipe_in <= i_send { |i|  [i.dst, ip_port, i.payload, i.payload] }
	  
	  stdio <~ pipe_in { |p| [["PPPPPPPPPPPPPPPIIIIIIIIIIIIIIPPPPPPPPPPPPPEEEEEEEEEEEEEIIIIIIIIIIINNNNNNNNNNNNNN #{p}"]] }
	  
	end
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
	  bcast
	  sleep(1)
	  stdio <~ [["Sending a message..."]]
  end
  
  def sendMsg2(wait_time)
	return [@server, [ip_port, "", "Hello from " << ip_port, "" ]]
  end
  
  def to_QVC(m_qvv)
    qvv= Bud::MapLattice.new
    m_qvv.each { |key,val|
      qvv= qvv.merge( Bud::MapLattice.new({key=>Bud::MaxLattice.new(val)}))
    }
    return qvv
  end
  
  def stopProcess
	stop
  end
  
end

if(ARGV.length < 2)
  puts "Client must be launch with ARGV[0]:id, ARGV[1]:k entries"
else
  server = (ARGV.length == 3) ? ARGV[2] : RaspbuddiesProtocol::DEFAULT_ADDR
	  

  puts "------------------------------------------"
  puts "                Run Client"
  puts "  Server address: #{server}"
  puts "------------------------------------------"

  program = Raspbuddies.new(ARGV[0], ARGV[1], server, :stdin => $stdin )

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
end



