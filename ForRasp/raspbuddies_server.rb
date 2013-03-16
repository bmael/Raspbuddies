require 'rubygems'
require 'backports'
require 'bud'
require_relative 'raspbuddies_protocol'

class RaspbuddiesServer
  include Bud
  include RaspbuddiesProtocol

  bloom do
    nodelist <= connect { |c| [c.client, c.id] } # Store new client persistently
    stdio <~ nodelist.inspected
	
	# send new client on channel new_client to all clients
    new_client <~ (nodelist * nodelist).pairs { |m,n| [n.key, m.values]} 
	stdio <~ nodelist { |c| [["nodelist : ",c.key, c.val]]}
	
	mcast <~ (mcast * nodelist).pairs { |m,n| [n.key, m.val] }

  end
end

# ruby command-line wrangling
addr = ARGV.first ? ARGV.first : RaspbuddiesProtocol::DEFAULT_ADDR
ip, port = addr.split(":")
puts "Server address: #{ip}:#{port}"
program = RaspbuddiesServer.new(:ip => ip, :port => port.to_i)
program.run_fg