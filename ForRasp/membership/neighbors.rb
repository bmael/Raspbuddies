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

module NeighborsProtocol
   state do
      interface input, :pipe_join, [:dst]
   end
end

module Neighbors
   include NeighborsProtocol
   
   state do
      channel :chn_join, [:@dst, :src, :clock, :answer, :data]
      channel :chn_share_neighbors, [:@dst, :src, :clock, :answer, :data]
      periodic :timer_share_neighbors, @shareTime

      table :neighbors, [:ip] => [:clock]
      scratch :remove_neighbor, neighbors.schema
      
      lmax :clock
   end
   
   bootstrap do
      clock <+ Bud::MaxLattice.new(0)
   end
   
   #----------------------------------------------------------------------------------
   #----------------------------------------------------------------------------------
   #
   #     JOIN THE NETWORK
   #
   #----------------------------------------------------------------------------------
   #----------------------------------------------------------------------------------
   
   bloom :ask_join_network do
      # Insertion request
      clock <+ pipe_join { |m| Bud::MaxLattice.new(clock.reveal) + 1 }
      chn_join <~ pipe_join { |m| [m.dst, ip_port, clock.reveal, false, ""] }
      
      # Receive answer to insertion request
      neighbors <+- chn_join { |m| incNeighborsCount(m.data) if m.answer == true && m.data[0] != ip_port }
      remove_neighbor <= neighbors.argmin([:ip], :clock) { |n| syncWithBudtime(n) if @select != @budtime }
      neighbors <- remove_neighbor { |n| decNeighborsCount(n) if @actual > @max }
   end
   
   bloom :answer_join_network do
      # Recevie insertion request
      clock <+ chn_join { |m| Bud::MaxLattice.new([clock.reveal, m.clock].max) + 1 }
      chn_join <~ chn_join { |m| [m.src, ip_port, clock.reveal, true, [ip_port, clock.reveal]] if m.answer == false }
      chn_join <~ (chn_join * neighbors).pairs { |m, n| [m.src, ip_port, clock.reveal, true, n] if m.answer == false }
   end
   
   private
   def incNeighborsCount(n)

			puts "ACTUAL = #{@actual}"

      k = neighbors.keys
      k.map! { |m| m[0] }
      if k.index(n[0]) == nil
        @actual = @actual + 1
      end
      return n
   end
   
   private
   def decNeighborsCount(n)
      @actual = @actual - 1
      return n
   end
   
   private
   def syncWithBudtime(n)
      @select = @budtime
      return n
   end
   
   #----------------------------------------------------------------------------------
   #----------------------------------------------------------------------------------
   #
   #     SHARE ITS NEIGHBOR TABLE
   #
   #----------------------------------------------------------------------------------
   #----------------------------------------------------------------------------------
   
   bloom :ask_share_neighbors do
      # Exchange request
      clock <+ timer_share_neighbors { |m| Bud::MaxLattice.new(clock.reveal) + 1 }
      chn_share_neighbors <~ timer_share_neighbors { |t| [randomNeighborAddress(neighbors), ip_port , clock.reveal, false, ""] if neighbors.length > 0 }
      chn_share_neighbors <~ timer_share_neighbors { |t| [@selectedNeighbor, ip_port, clock.reveal, true, [ip_port, clock.reveal]] if neighbors.length > 0 && @selectedNeighbor != "" }
      chn_share_neighbors <~ (timer_share_neighbors * neighbors).pairs { |t, n| [@selectedNeighbor, ip_port, clock.reveal, true, n] if neighbors.length > 0 && @selectedNeighbor != "" }
      
      # Receive anwser to exchange request
      neighbors <+- chn_share_neighbors { |m| incNeighborsCount(m.data) if m.answer == true && m.data[0] != ip_port }
   end
   
   bloom :answer_share_neighbors do
      # Receive anwser to share neigbhor table
      clock <+ chn_share_neighbors { |m| Bud::MaxLattice.new([clock.reveal, m.clock].max) + 1 }
      chn_share_neighbors <~ chn_share_neighbors { |m| [m.src, ip_port, clock.reveal, true, [ip_port, clock.reveal]] if m.answer == false }
      chn_share_neighbors <~ (chn_share_neighbors * neighbors).pairs { |m, n| [m.src, ip_port, clock.reveal, true, n] if m.answer == false }
   end
   
   private
   def randomNeighborAddress(table)
      @selectedNeighbor = table.keys.at(rand(neighbors.length))[0]
      return @selectedNeighbor
   end
end
