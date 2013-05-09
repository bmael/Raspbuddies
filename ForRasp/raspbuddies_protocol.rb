require_relative "lattice/LQVC"
require_relative './delivery/multicast'

module RaspbuddiesProtocol
  include StaticMembership
  include BestEffortMulticast
  
  state do
    channel :connect, [:@addr, :client] => [:id]
    channel :mcast
    channel :my_msg
	
    channel :new_client
  end

  DEFAULT_ADDR = "localhost:12348" # to modify with the real server ip

end

