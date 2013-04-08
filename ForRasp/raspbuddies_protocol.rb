require_relative "lattice/LQVC"
require_relative './delivery/multicast'

# module TestState
#   include StaticMembership
# 
#   state do
#     table :mcast_done_perm, mcast_done.schema
#     table :rcv_perm, [:ident] => [:payload]
#   end
# 
#   bloom :mem do
#     mcast_done_perm <= mcast_done
#     rcv_perm <= pipe_out {|r| [r.ident, r.payload]}
#   end
# end

# class MC
#   include Bud
#   include TestState
#   include BestEffortMulticast
# end

module RaspbuddiesProtocol
  include StaticMembership
  include BestEffortMulticast
  
  state do
    channel :connect, [:@addr, :client] => [:id]
    channel :mcast
    channel :my_msg
	
	
#     table :nodelist #Contains all clients information
    channel :new_client
	
	
	interface input, :i_send, [:dst] => [:payload]
  end

  DEFAULT_ADDR = "localhost:12346" # to modify with the real server ip

end

