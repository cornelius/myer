require_relative "spec_helper.rb"

describe ProcNetParser do
  it "parses received bytes" do
    input = <<EOT
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:  773884    8999    0    0    0     0          0         0   773884    8999    0    0    0     0       0          0
enp0s5: 967587512  749231    0    0    0     0          0      1896 40848584  466347    0    0    0     0       0          0
EOT
    parser = ProcNetParser.new
    parser.parse input
    expect(parser.received_bytes).to eq 967587512
  end
end
