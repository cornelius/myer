require "pty"

class XinputParser

  attr_accessor :mouse_id
  
  def track_clicks(mouse_id=nil)
    if !mouse_id
      mouse_id = parse_list(`xinput list`)
    end
    PTY.spawn("xinput test #{mouse_id}") do |r, w, pid|
      parse_clicks(r) do
        yield
      end
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
  
  def parse_clicks(input)
    input.each_line do |line|
      if line =~ /^button press/
        yield
      end
    end
  end
end
