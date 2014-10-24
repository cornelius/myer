require_relative "spec_helper.rb"

describe Plot do
  it "calls helper script" do
    @plot = Plot.new
    expect(@plot).to receive(:call_helper)
    @plot.show("csv_file")
  end
end
