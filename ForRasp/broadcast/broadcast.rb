#################################################################
#
#  Raspbuddies
#  University of Nantes
#  M2 -Alma
#  2012 - 2013
#
################################################################# 
#
#  Matthieu Allon - Pauline Folz - Teko Hemazro - Amine Lyazid
#  Adrien Quillet - Nicolas Rault - Kévin Simon
#
#################################################################

require "rubygems"
require "bud"

module BroadcastProtocol
   state do
      interface input, :bcast_send, [:content] => [:ttl]
   end
end

module Broadcast
   include BroadcastProtocol

   # Send message across the network
   bloom :snd_bcast do
      next_vc <= bcast_send.flat_map do |m|
         @my_entries.map { |e| { e => vc.at(e) + 1 } }
      end
      vc <+ next_vc
      
      chn <~ (bcast_send * neighbors).pairs { |m, n| [n[0], ip_port, @my_entries, m.ttl, m.content, next_vc] }
   end
   
    # Message is rebroadcast to neighbors if the TTL is greater than 0
   bloom :done_bcast do
      chn <~ (pipe_sent * neighbors).pairs { |m, n| [n[0], ip_port, m.src_entries, (m.ttl - 1), m.content, m.clock] if m.ttl - 1 > 0 }
   end
end