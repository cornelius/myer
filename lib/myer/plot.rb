class Plot
  def call_helper(csv_file_path)
    plot_helper = File.expand_path( "../../../scripts/plot-helper.py", __FILE__ )
    cmd = "python #{plot_helper} #{csv_file_path}"
    system(cmd)
  end

  def show(csv_file)
    call_helper(csv_file)
  end
end
