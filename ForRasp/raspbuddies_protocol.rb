require_relative "lattice/LQVC"
require_relative "./delivery"

module RaspbuddiesProtocol
  include DeliveryProtocol
  
  
  state do
    channel :connect, [:@addr, :client] => [:id]
    channel :chn, [:@dst, :src, :ident] => [:payload, :m_qvc, :m_entries]
    channel :mcast
    
    table :nodelist #Contains all clients information
    channel :new_client
    
    lqvc :my_qvc
    lqvc :next_qvc
    
    table :recv_buf, chn.schema
    scratch :buf_chosen, recv_buf.schema
    
  end

  DEFAULT_ADDR = "localhost:12345"

  bloom :update_qvc do
    # outgoing messages:
    next_qvc <= pipe_in { my_qvc.next_qvc(Set.new(@entries)) }
    # incoming messages:
    next_qvc <= buf_chosen { |m| LQVC.new([m.m_qvc,Set.new(m.m_entries)]) }
    # update qvc
    my_qvc <+ next_qvc #(D) mendatory to maintain the order ???
  
#   miaou <~ next_qvc
#   next_qvc <= miaou
## myqvc <= miaou ??
  end

  bloom :outbound_msg do
    chn <~ pipe_in { |p|
      [ p.dst,
        p.src,
        p.ident,
        p.payload,
        my_qvc.next_qvc(Set.new(@entries)).qvc,
        @entries ]
    }
    pipe_sent <= pipe_in
  end

  bloom :inbound_msg do
    recv_buf <= chn
    buf_chosen <= recv_buf { |m|
      my_qvc.rdy(LQVC.new([m.m_qvc,Set.new(m.m_entries)]),Set.new(@entries))
      .when_true{ m }
    }
    recv_buf <- buf_chosen #(D)

    pipe_out <= buf_chosen { |m|
      [m.dst,m.src,m.ident, m.payload]
    }
  end

end

