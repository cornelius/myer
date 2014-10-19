require_relative "spec_helper.rb"

describe XinputParser do
  before(:each) do
    @parser = XinputParser.new
  end
  
  it "finds mouse" do
    input = <<EOT
⎡ Virtual core pointer                          id=2    [master pointer  (3)]
⎜   ↳ Virtual core XTEST pointer                id=4    [slave  pointer  (2)]
⎜   ↳ ImExPS/2 Generic Explorer Mouse           id=9    [slave  pointer  (2)]
⎣ Virtual core keyboard                         id=3    [master keyboard (2)]
    ↳ Virtual core XTEST keyboard               id=5    [slave  keyboard (3)]
    ↳ Power Button                              id=6    [slave  keyboard (3)]
    ↳ Sleep Button                              id=7    [slave  keyboard (3)]
    ↳ AT Translated Set 2 keyboard              id=8    [slave  keyboard (3)]
EOT

    expect(@parser.parse_list(input)).to eq "9"
  end

  it "finds clicks" do
    input = <<EOT
motion a[0]=649 a[1]=531 
motion a[0]=649 a[1]=532 
button press   1 
button release 1 
button press   1 
button release 1 
motion a[0]=655 a[1]=531 
motion a[0]=649 a[1]=542 
button press   1 
button release 1 
motion a[0]=650 a[1]=542     
EOT

    output = double
    expect(output).to receive(:puts).with("Click").exactly(3).times
    
    @parser.parse_clicks(input, output)
  end 
end
