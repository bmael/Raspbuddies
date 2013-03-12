module RaspbuddiesProtocol
  state do
    channel :connect, [:@addr, :client] => [:id]
    channel :mcast
  end

  DEFAULT_ADDR = "localhost:12345"
end
