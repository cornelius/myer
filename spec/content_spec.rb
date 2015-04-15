require "spec_helper.rb"

include GivenFilesystemSpecHelpers

describe Content do
  use_given_filesystem

  before(:each) do
    @content = Content.new
  end

  it "parses item" do
    @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"[\"2014-06-02\",\"37\"]"}')

    item = @content.first

    expect(item.id).to eq "63705782"
    expect(item.written_at).to eq "2014-10-24T12:53:17Z"
    expect(item.data).to eq ["2014-06-02", "37"]
  end

  it "receives title" do
    @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"title","data":"My Title"}')

    expect(@content.empty?).to be true
    expect(@content.title).to eq "My Title"
  end

  it "receives multiple items" do
    @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:38Z","data":"[\"2014-06-03\",\"37\"]"}')
    @content.add('{"id":"63758143","written_at":"2014-10-24T12:53:49Z","data":"[\"2014-06-04\",\"39\"]"}')

    expect(@content.length).to eq 2
    expect(@content.at(0).data[1]).to eq "37"
    expect(@content.at(1).data[1]).to eq "39"
  end

  it "writes data as CSV" do
    @content.add('{"data":"[\"2014-06-03\",\"37\"]"}')
    @content.add('{"data":"[\"2014-06-04\",\"39\"]"}')

    output_path = given_dummy_file

    @content.write_as_csv(output_path)
    expect(File.read(output_path)).to eq(<<EOT
2014-06-03,37
2014-06-04,39
EOT
    )
  end

  it "writes data as JSON" do
    @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"title","data":"My Title"}')
    @content.add('{"data":"[\"2014-06-03\",\"37\"]"}')
    @content.add('{"data":"[\"2014-06-04\",\"39\"]"}')

    output_path = given_dummy_file

    expected_json = "{\"title\":\"My Title\",\"data\":[{\"date\":\"2014-06-03\",\"value\":\"37\"},{\"date\":\"2014-06-04\",\"value\":\"39\"}]}"


    @content.write_as_json(output_path)
    expect(File.read(output_path)).to eq(expected_json)
  end
end
