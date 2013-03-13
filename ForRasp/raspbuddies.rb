require 'rubygems'
require 'bud'
require 'backports'	
require_relative 'raspbuddies_protocol'

class Raspbuddies
  include Bud
  include RaspbuddiesProtocol
 
  
  SPAM_FREQUENCY = 0.5

  def initialize(id, server, opts={})
    @id = id
    @server = server
    super opts
  end
  
  bootstrap do
    connect <~ [[@server, ip_port, @id]]
  end
  
  bloom :rcv do
     mcast <~ stdio do 
		    sendMsg(SPAM_FREQUENCY)
		    end     
  end
  
  bloom :snd do 
         stdio <~ mcast { |m| [logIntoFile(m.val)] if m.val[0] != @id} # don't log if we are the msg sender.
  end
  
  #TODO : 
  #method to send a message all K ms to another process
  def sendMsg(wait_time) 
      sleep(wait_time)
      return [@server, [@id, "Hello from "<<@id ]]
  end
  
  #DONE :
  # Log a message into the file log.
  def logIntoFile(msg)
    File.open("log"<<@id, 'a') {|f| f.write(msg) 
				f.write("\n")  }
    return  msg 	
  end
  
end

server = (ARGV.length == 2) ? ARGV[1] : RaspbuddiesProtocol::DEFAULT_ADDR
puts "Server address: #{server}"
program = Raspbuddies.new(ARGV[0], server, :stdin => $stdin )
program.run_fg

