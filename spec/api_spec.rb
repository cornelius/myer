require "spec_helper"

describe MySelf::Api do
  before(:each) do
    @api = MySelf::Api.new
    @api.server = "example.org"
    @api.user = "abc"
    @api.password = "def"
  end

  describe "#admin_register" do
    it "registers admin client" do
      pin = "4444"
      expected_id = "12"
      expected_password = "s3cr3t"

      body = "{\"admin_id\":\"#{expected_id}\",\"password\":\"#{expected_password}\"}"
      stub_request(:post, "http://example.org:4735/admin/register/#{pin}").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => body, :headers => {})

      id, password = @api.admin_register(pin)

      expect(id).to eq expected_id
      expect(password).to eq expected_password
    end

    it "fails when admin client is already registered" do
      stub_request(:post, "http://example.org:4735/admin/register/1234").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 400, :body => 'Client is already registered', :headers => {})

      expect {
        @api.admin_register("1234")
      }.to raise_error
    end
  end

  describe "#admin_list_buckets" do
    it "returns buckets" do
      buckets = [ "a", "b" ]

      body = "[" + buckets.map{ |b| "\"#{b}\"" }.join(",") + "]"
      stub_request(:get, "http://abc:def@example.org:4735/admin/buckets").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => body, :headers => {})

      expect(@api.admin_list_buckets).to eq buckets
    end
  end

  describe "#create_token" do
    it "returns token" do
      token = "xxxxx"

      body = "{\"token\":\"#{token}\"}"
      stub_request(:post, "http://abc:def@example.org:4735/tokens").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => body, :headers => {})

      expect(@api.create_token).to eq token
    end
  end

  describe "#register" do
    it "registers client" do
      token = "x"

      stub_request(:post, "http://example.org:4735/register/#{token}").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => '{"user_id":"157610723","user_password":"626078090"}', :headers => {})

      user, password = @api.register(token)

      expect(user).to eq "157610723"
      expect(password).to eq "626078090"
    end
  end

  describe "#create_bucket" do
    it "creates new bucket" do
      stub_request(:post, "http://abc:def@example.org:4735/data").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => '{"bucket_id":"150479372"}', :headers => {})

      expect(@api.create_bucket).to eq "150479372"
    end
  end

  describe "#create_item" do
    it "creates item" do
      bucket_id = "123"
      content = "my data"

      stub_request(:post, "http://abc:def@example.org:4735/data/#{bucket_id}").
        with(:body => content, :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => '{"item_id":"504885608","parent_id":"772806166"}', :headers => {})

      expect(@api.create_item(bucket_id, content)).to eq "504885608"
    end
  end

  describe "#get_items" do
    it "reads raw items" do
      bucket_id = "987654321"
      stub_request(:get, "http://abc:def@example.org:4735/data/#{bucket_id}").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '[{"item_id":"263800370","parent_id":"271086077","content":"more data"},{"item_id":"271086077","parent_id":"","content":"my data"}]', :headers => {})

      expected_items = [
        OpenStruct.new(id: "271086077", content: "my data"),
        OpenStruct.new(id: "263800370", content: "more data")
      ]
      expect(@api.get_items(bucket_id)).to eq expected_items
    end
  end
end
