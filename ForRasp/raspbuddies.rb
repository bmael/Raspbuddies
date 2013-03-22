require 'rubygems'
require 'bud'
require 'backports'	
require_relative 'raspbuddies_protocol'

class Raspbuddies
  include Bud
  include RaspbuddiesProtocol
 
  
  SPAM_FREQUENCY = 0.5

#   state do
#     interface input, :i_send, [:dst] => [:payload]
#   end
  
  state do 
	channel :tmp
  end
	
  def initialize(id, server, opts={})
    @id = id
    @server = server
    super opts
  end
  
  bootstrap do
    connect <~ [[@server, ip_port, @id]]
  end
  
#     bloom :rcv do
# # stdio <~ pipe_out { |m| ["pipe_out= "+ m.payload.to_s]} #debugz
#   end
  
#   bloom :log do
#     stdio <~ log { puts "==="+log.inspected.to_s+"===" } #debugz
#   end
  
#   bloom :snd do
#     pipe_in <= i_send { |i|
#       [i.dst, ip_port, i.payload, i.payload]
#     }
#   end
  
  ###########################################################################
  ##								BLOOM LOOP								 ##
  ###########################################################################
  
  # Send a message
  bloom :snd do
		# send message to all clients
# 	   mcast <~ (mcast * nodelist).pairs { |m,n| [n.key, m.val] }
	   mcast <~ stdio { sendMsg(SPAM_FREQUENCY)}
# 	   stdio <~ [[doEnter()]]
  end
  
  # Receive a message
  bloom :rcv do 
	stdio <~ mcast { |m| [["LOG received message", logIntoFile(m.val)]] if m.val[0] != ip_port } # don't log if we are the msg sender
# 	resend <~ mcast { |m| [["Receiving my message"]] if m.val[0] == @id}
	
	stdio <~ mcast { |m| [["Receiving my message"]] if m.val[0] == ip_port} # advise that you received your message
	mcast <~ stdio #Throws an exception... have to find a better solution for infinite loop
# 	stdio <~ mcast { |m| [["Sending JAM string"]] if m.val[0] == @id}
# 	mcast <~ stdio do [@server,[@id, "", "JAM String", ""]] end
# 	mcast <~ stdio { sendMsg(SPAM_FREQUENCY) }
	
	

	# 	 my_qvc <= mcast { |m| LQVC.new([m.m_qvc, Set.new(m.m_entries)]) if m.val[0] != @id}
  end
  
  # New clients detected by central server
  bloom :update_nodelist do
# 	nodelist <= new_client { |c| [c.val] }
# 	stdio <~ new_client { |c| [["udpate_client", c.val, "end update client"]] }
	stdio <~ new_client { |c| [["new client", c.val]]}
	stdio <~ nodelist{ |c| [["nodelist", c.val]]}
  end
   
  ###########################################################################
  ##							RUBY METHODS								 ##
  ###########################################################################
   # Log a message into the file log.
  def logIntoFile(msg)
    File.open("log/log" << ip_port, 'a') {|f| f.write(msg) 
				f.write("\n")  }
    return  msg 	
  end
  
  def sleepFor(k)
	sleep(k)
  end
  
  def doEnter()
	$stdout.puts "\n"
	return "Enter pressed"
  end
  
  #method to send a message all K ms to another process
  def sendMsg(wait_time) 
#       sleep(wait_time)
      return [@server, [ip_port, "", "Hello from " << ip_port, "" ]]
  end
  
  def printClients(table)
    return table.inspected
  end
  
end

#TODO : Have to find a solution for the loop to send msg...
if(ARGV.length < 1) 
  puts "You must give an id for this process..."
  puts "Type : > ruby raspbuddies.rb [id_process]"
else
  server = (ARGV.length == 2) ? ARGV[1] : RaspbuddiesProtocol::DEFAULT_ADDR
  puts "Server address: #{server}"
  program = Raspbuddies.new(ARGV[0], server, :stdin => $stdin )
#   program.printClients
  program.run_fg
end


