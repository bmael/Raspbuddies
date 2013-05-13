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

require_relative '../delivery/causal.rb'
require_relative 'broadcast.rb'
require_relative '../membership/neighbors.rb'
require_relative 'HashModule.rb'

module Debug
   private
   def lmapToArray(map)
      result = []
      (0..@vcSize-1).each do |i|
         result.insert(0, map.at(i).reveal)
      end
      return result.reverse
   end
   
   private
   def showNeighborsTable(table)
      result = "\tVoisinage : \n"
      table.each do |n|
         result = result + "\t\t" + n.inspect + "\n"
      end
      return result + "\n\n"
   end
   
   private
   def deliver()
      result = "\n\t\t\t\t\t\t\t"
      i = @name.delete("T").to_i
      (0..i).each do |t|
         result = result + "\t"
      end
      result = result + "in T" + i.to_s + "\n\t\t\t\t\t\t\t"
      (0..i).each do |t|
         result = result + "\t"
      end
      return result
   end
   
   state do
      interface input, :pipe_poubelle, [:dst]
      channel :chn_poubelle, [:@dst]
   end
   
   bloom :debug do
      chn_poubelle <~ pipe_poubelle { |m| [m.dst] }
      stdio <~ bcast_send {|m| ["(#{@budtime}) #{@name} broadcast -- #{m.content}"]}
      stdio <~ pipe_out {|m| ["#{deliver()}#{m.content}\n"]}
      stdio <~ buffer_msg {|c| ["(#{@budtime}) Inbound message in #{@name} from #{c.src} -- #{c.content} -- #{c.ttl}"]}
   end
end

module CausalBroadcast
   include CausalDelivery
   include Neighbors
   include Broadcast
   include Debug
   include HashFunctions
end

class CausalAgent
   include Bud
   include CausalBroadcast
   
   attr_reader :idProcess, :my_entries
   
   def initialize(name, opts = {})
      @shareTime = 0.01
      @name = name
      @vcSize = 41
      @max = 10
      @actual = 0
      @select = 0
      @selectedNeighbor = ""
      
      super opts

      
   end
   
   def initProcess()
      @idProcess = ip_port
      @my_entries = hashKey(@idProcess)
      
      puts "\t" + @name + " = " + @idProcess.to_s + " : " + @my_entries.inspect
   end
end
