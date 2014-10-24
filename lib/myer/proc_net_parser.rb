class ProcNetParser
  attr_reader :received_bytes

  def parse(input)
    input.each_line do |line|
      if line =~ /^en(.*):\s+(\d+)\s+/
        @received_bytes = $2.to_i
      end
    end
  end
end
