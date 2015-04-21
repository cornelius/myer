require "spec_helper.rb"

include GivenFilesystemSpecHelpers

describe Content do
  use_given_filesystem

  before(:each) do
    @content = Content.new("12345678")
  end

  describe "array methods" do
    describe "#first" do
      it "returns first item" do
        @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"one"}')

        expect(@content.first.data).to eq("one")
      end
    end

    describe "#at" do
      before(:each) do
        @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"one"}')
        @content.add('{"id":"63705783","written_at":"2014-10-24T12:53:17Z","data":"two"}')
      end

      it "returns first item" do
        expect(@content.at(0).data).to eq("one")
      end

      it "returns second item" do
        expect(@content.at(1).data).to eq("two")
      end
    end

    describe "#empty?" do
      it "returns that list is empty" do
        expect(@content.empty?).to be(true)
      end

      it "returns that list is not empty" do
        @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"one"}')

        expect(@content.empty?).to be(false)
      end
    end

    describe "#length" do
      it "returns length of empty list" do
        expect(@content.length).to eq(0)
      end

      it "returns length of list with one item" do
        @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"one"}')

        expect(@content.length).to eq(1)
      end

      it "returns length og list with two items" do
        @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"one"}')
        @content.add('{"id":"63705783","written_at":"2014-10-24T12:53:17Z","data":"two"}')

        expect(@content.length).to eq(2)
      end
    end
  end

  describe "types" do
    it "receives type tag" do
      @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"type","data":"sometype"}')

      expect(@content.empty?).to be true
      expect(@content.type).to eq "sometype"
    end

    it "parses quoted JSON" do
      @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"type","data":"json"}')
      @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"[\"2014-06-02\",\"37\"]"}')

      item = @content.first

      expect(item.id).to eq "63705782"
      expect(item.written_at).to eq "2014-10-24T12:53:17Z"
      expect(item.data).to eq ["2014-06-02", "37"]
    end

    it "parses untyped data" do
      @content.add('{"id":"63705782","written_at":"2014-10-24T12:53:17Z","data":"42"}')

      item = @content.first

      expect(item.id).to eq "63705782"
      expect(item.written_at).to eq "2014-10-24T12:53:17Z"
      expect(item.data).to eq "42"
    end
  end

  it "receives title" do
    @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"title","data":"My Title"}')

    expect(@content.empty?).to be true
    expect(@content.title).to eq "My Title"
  end

  it "receives multiple items" do
    @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"type","data":"json"}')
    @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:38Z","data":"[\"2014-06-03\",\"37\"]"}')
    @content.add('{"id":"63758143","written_at":"2014-10-24T12:53:49Z","data":"[\"2014-06-04\",\"39\"]"}')

    expect(@content.length).to eq 2
    expect(@content.at(0).data[1]).to eq "37"
    expect(@content.at(1).data[1]).to eq "39"
  end

  describe "remove item" do
    it "in untyped container" do
      @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:38Z","data":"[\"2014-06-03\",\"37\"]"}')
      expect(@content.length).to eq 1
      @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:49Z","data":""}')
      expect(@content.length).to eq 0
    end

    it "in JSON container" do
      @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"type","data":"json"}')
      @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:38Z","data":"[\"2014-06-03\",\"37\"]"}')
      expect(@content.length).to eq 1
      @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:49Z","data":""}')
      expect(@content.length).to eq 0
    end
  end

  it "overwrites item" do
    @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:38Z","data":"one"}')
    expect(@content.length).to eq 1
    @content.add('{"id":"92285309","written_at":"2014-10-24T12:53:49Z","data":"two"}')
    expect(@content.length).to eq 1
    expect(@content.first.data).to eq "two"
  end

  describe "writes data as CSV" do
    it "from JSON" do
      @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"type","data":"json"}')
      @content.add('{"id":"123","data":"[\"2014-06-03\",\"37\"]"}')
      @content.add('{"id":"124","data":"[\"2014-06-04\",\"39\"]"}')

      output_path = given_dummy_file

      @content.write_as_csv(output_path)
      expect(File.read(output_path)).to eq(<<EOT
2014-06-03,37
2014-06-04,39
EOT
      )
    end

    it "from untyped data" do
      @content.add('{"id":"123","data":"37"}')
      @content.add('{"id":"124","data":"39"}')

      output_path = given_dummy_file

      @content.write_as_csv(output_path)
      expect(File.read(output_path)).to eq(<<EOT
37
39
EOT
      )
    end
  end

  it "writes data as JSON" do
    @content.add('{"id":"15938189","written_at":"2014-10-24T12:52:42Z","tag":"type","data":"json"}')
    @content.add('{"id":"15938190","written_at":"2014-10-24T12:52:42Z","tag":"title","data":"My Title"}')
    @content.add('{"id":"123","data":"[\"2014-06-03\",\"37\"]"}')
    @content.add('{"id":"124","data":"[\"2014-06-04\",\"39\"]"}')

    output_path = given_dummy_file

    expected_json = <<EOT
{
  "bucket_id": "12345678",
  "title": "My Title",
  "data": [
    {
      "date": "2014-06-03",
      "value": "37"
    },
    {
      "date": "2014-06-04",
      "value": "39"
    }
  ]
}
EOT

    @content.write_as_json(output_path)
    expect(File.read(output_path)).to eq(expected_json.chomp)
  end
end
