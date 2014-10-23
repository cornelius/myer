class CliController

  def track_clicks(mouse_id)
    XinputParser.new.track_clicks(mouse_id) do
      puts "CLICK"
    end
  end

end
