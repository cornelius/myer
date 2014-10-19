require "pty"

class XinputParser

  attr_accessor :mouse_id
  
  def track_clicks
    mouse_id = parse_list(`xinput list`)
    PTY.spawn("xinput test #{mouse_id}") do |r, w, pid|
      parse_clicks(r, STDOUT)
    end
  end
  
  def parse_list(input)
    input.each_line do |line|
      if line =~ /Mouse.*id=(\d+)/
        return $1
      end
    end
    nil
  end
  
  def parse_clicks(input,output)
    input.each_line do |line|
      if line =~ /^button press/
        output.puts("Click")
      end
    end
  end
end
