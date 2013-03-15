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
  bloom :snd do
     mcast <~ stdio { sendMsg(SPAM_FREQUENCY) }
  end
  
  bloom :rcv do 
         stdio <~ mcast { |m| [logIntoFile(m.val)] if m.val[0] != @id} # don't log if we are the msg sender
# 	 my_qvc <= mcast { |m| LQVC.new([m.m_qvc, Set.new(m.m_entries)]) if m.val[0] != @id}
  end
   
   # Log a message into the file log.
  def logIntoFile(msg)
    File.open("log"<<@id, 'a') {|f| f.write(msg) 
				f.write("\n")  }
    return  msg 	
  end
  
  #method to send a message all K ms to another process
  def sendMsg(wait_time) 
      sleep(wait_time)
      return [@server, [@id, "", "Hello from "<<@id, "" ]]
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
  program.run_fg
end


