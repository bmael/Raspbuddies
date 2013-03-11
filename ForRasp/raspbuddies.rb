require 'rubygems'
require 'bud'
require 'backports'	
require_relative 'raspbuddies_protocol'

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
  
  bloom do
     mcast <~ stdio do 
		    sendMsg("coucou")
		    end
		    
     stdio <~ mcast { |m| [logIntoFile(m.val)] } 
     
  end
  
  #TODO : 
  #method to send a message all K ms to another process
  def sendMsg(msg) 
      return [@server, [@id, msg]] 
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

