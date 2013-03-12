require 'rubygems'
require 'backports'
require 'bud'
require_relative 'raspbuddies_protocol'

class RaspbuddiesServer
  include Bud
  include RaspbuddiesProtocol

  state { table :nodelist }

  bloom do
    nodelist <= connect { |c| [c.client, c.id] }
    mcast <~ (mcast * nodelist).pairs { |m,n| [n.key, m.val] }
  end
end

# ruby command-line wrangling
addr = ARGV.first ? ARGV.first : RaspbuddiesProtocol::DEFAULT_ADDR
ip, port = addr.split(":")
puts "Server address: #{ip}:#{port}"
program = RaspbuddiesServer.new(:ip => ip, :port => port.to_i)
program.run_fg