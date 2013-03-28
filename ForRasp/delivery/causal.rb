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

module DeliveryProtocol
   state do
      interface input, :pipe_sent, [:dst, :src, :ttl] => [:clock, :src_entries, :content]
      interface output, :pipe_out, [:dst, :src] => [:ttl, :content, :clock, :src_entries]
   end
end

module CausalDelivery
   include DeliveryProtocol
   
   state do
      channel :chn, [:@dst, :src, :src_entries, :ttl, :content] => [:clock]
      
      table :buffer_msg, chn.schema
      table :invalid_msg, chn.schema
      scratch :first_chosen, chn.schema
      scratch :second_chosen, chn.schema

      lmap :vc
      lmap :next_vc
   end
   
   bootstrap do
      (0..@vcSize-1).each do |i|
         vc <= { i => Bud::MaxLattice.new(0) }
         next_vc <= { i => Bud::MaxLattice.new(0) }
      end
   end
   
   bloom :broadcast_msg do
      pipe_sent <+ chn { |m| [m.dst, m.src, m.ttl, m.clock, m.src_entries, m.content] }
   end

   bloom :inbound_message do
      buffer_msg <= chn { |m| m if m.src != ip_port && !(m.src_entries.map {|e| m.clock.at(e).reveal > vc.at(e).reveal}).include?(false) }
      # Contains duplicates and recovery messages
      invalid_msg <= chn { |m| m if m.src != ip_port && !(m.src_entries.map {|e| m.clock.at(e).reveal <= vc.at(e).reveal}).include?(false) }
            
      first_chosen <= buffer_msg { |m| m if !(m.src_entries.map {|e| m.clock.at(e).reveal - 1 <= vc.at(e).reveal}).include?(false) }
      second_chosen <= first_chosen { |m| m if !((Array.new(@vcSize-1) {|i| i}).map {|e| @my_entries.include?(e) || m.src_entries.include?(e) || (m.clock.at(e).reveal <= vc.at(e).reveal)}).include?(false) }
      buffer_msg <- second_chosen
      
      next_vc <= second_chosen.flat_map do |m|
         m.src_entries.map { |e| { e => vc.at(e) + 1 } if !(m.src_entries.map {|i| m.clock.at(i).reveal - 1 == vc.at(i).reveal}).include?(false) }
      end
      
      vc <+ next_vc
      
      buffer_msg <- second_chosen
      pipe_out <= second_chosen { |m| [m.dst, m.src, m.ttl, m.content, m.clock, m.src_entries] }
   end
end