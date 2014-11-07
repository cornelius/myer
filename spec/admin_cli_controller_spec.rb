require_relative "spec_helper.rb"

include GivenFilesystemSpecHelpers

describe AdminCliController do
  use_given_filesystem

  before(:each) do
    @controller = AdminCliController.new
  end

  describe "remembers state" do
    it "writes state to config file" do
      config_dir = File.join(given_directory, "subdir")
      @controller.config_dir = config_dir

      @controller.server = "example.com"
      @controller.admin_id = "123"
      @controller.password = "456"
      @controller.default_bucket_id = "890"
      @controller.user_id = "abc"
      @controller.user_password = "xyz"

      @controller.write_state

      expect(File.read(File.join(config_dir,"myer.config"))).to eq(<<EOT
---
default_server: example.com
example.com:
  admin_id: '123'
  password: '456'
  user_id: abc
  user_password: xyz
  default_bucket_id: '890'
EOT
      )
    end

    it "reads state from config file" do
      config_dir = given_directory do
        given_file "myer.config", from: "myer-full.config"
      end
      @controller.config_dir = config_dir

      @controller.read_state

      expect(@controller.server).to eq "example.org"
      expect(@controller.admin_id).to eq "abc"
      expect(@controller.password).to eq "def"
      expect(@controller.user_id).to eq "ddd"
      expect(@controller.user_password).to eq "ggg"
      expect(@controller.default_bucket_id).to eq "987654321"
    end
  end

  describe "#register" do
    it "registers admin client" do
      @controller.config_dir = given_directory

      stub_request(:post, "http://example.com:4735/admin/register/1234").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"admin_id":"181504088","password":"683271947"}', :headers => {})

      @controller.register "example.com", "1234"

      expect(@controller.admin_id).to eq "181504088"
      expect(@controller.password).to eq "683271947"

      expect(File.read(File.join(@controller.config_dir, "myer.config"))).to eq (<<EOT
---
default_server: example.com
example.com:
  admin_id: '181504088'
  password: '683271947'
EOT
      )
    end

    it "fails when admin client is already registered" do
      stub_request(:post, "http://example.com:4735/admin/register/1234").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 400, :body => 'Client is already registered', :headers => {})

      expect {
        @controller.register "example.com", "1234"
      }.to raise_error
    end
  end

  describe "#create_bucket" do
    it "creates new bucket" do
      stub_request(:post, "http://ddd:ggg@example.org:4735/data").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"bucket_id":"150479372"}', :headers => {})

      config_file_path = nil
      @controller.config_dir = given_directory do
        config_file_path = given_file("myer.config", from: "myer-full.config")
      end

      bucket_id = @controller.create_bucket
      expect(bucket_id).to eq "150479372"

      expect(@controller.default_bucket_id).to eq bucket_id

      config = YAML.load_file(config_file_path)
      expect(config["example.org"]["default_bucket_id"]).to eq bucket_id

      ticket_file_path = File.join(@controller.config_dir, "secret-ticket-150479372.json")
      expect(File.exist?(ticket_file_path)).to be true
    end
  end

  describe "#list_buckets" do
    it "lists existing buckets" do
      stub_request(:get, "http://abc:def@example.org:4735/admin/buckets").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '["150479372","309029630"]', :headers => {})

      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      out = double
      expect(out).to receive(:puts).with("150479372")
      expect(out).to receive(:puts).with("309029630")
      @controller.out = out

      @controller.list_buckets
    end
  end

  describe "#write_item" do
    it "writes raw item" do
      stub_request(:post, "http://ddd:ggg@example.org:4735/data/309029630").
         with(:body => 'my data', :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"item_id":"504885608","parent_id":"772806166"}', :headers => {})

      @controller.config_dir = given_directory do
        given_file("myer.config", from: "myer-full.config")
      end

      item_id = @controller.write_item("309029630", "my data")

      expect(item_id).to eq "504885608"
    end
  end

  describe "#write" do
    it "writes encrypted item" do
      @controller.config_dir = given_directory do
        given_file("myer.config")
        given_file("secret-ticket-987654321.json")
      end

      @controller.read_state
      bucket_id = @controller.default_bucket_id

      allow_any_instance_of(Crypto).to receive(:encrypt).and_return("encrypted")

      expect(@controller).to receive(:write_item).with(bucket_id, "encrypted")

      @controller.write("some data")
    end
  end

  describe "#read_items" do
    it "reads raw items" do
      bucket_id = "987654321"
      stub_request(:get, "http://ddd:ggg@example.org:4735/data/#{bucket_id}").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '[{"item_id":"263800370","parent_id":"271086077","content":"more data"},{"item_id":"271086077","parent_id":"","content":"my data"}]', :headers => {})

      @controller.config_dir = given_directory do
        given_file("myer.config", from: "myer-full.config")
        given_file("secret-ticket-#{bucket_id}.json")
      end

      class TestCrypto < Crypto
        def decrypt(cipher)
          "A#{cipher}O"
        end
      end

      @controller.crypto = TestCrypto.new

      out = double
      expect(out).to receive(:puts).with("263800370: Amore dataO")
      expect(out).to receive(:puts).with("271086077: Amy dataO")
      @controller.out = out

      inner_items = @controller.read_items(bucket_id)

      expect(@controller.crypto.passphrase).to eq "secret key"
      expect(inner_items.count).to eq 2
      expect(inner_items[0]).to eq "Amy dataO"
      expect(inner_items[1]).to eq "Amore dataO"
    end
  end

  describe "#write_value" do
    it "writes value" do
      value = 42

      expect(@controller).to receive(:write_item)
      @controller.write_value(value)
    end
  end

  describe "#write_pair" do
    it "writes value pair" do
      expect(@controller).to receive(:write_value).with('["2014-10-24","42"]')

      @controller.write_pair("2014-10-24", "42")
    end
  end

  describe "#create_payload" do
    it "creates payload" do
      value = "some data"
      payload_string = @controller.create_payload(value)
      payload = JSON.parse(payload_string)
      expect(payload["id"].length).to be > 6
      expect(payload["written_at"]).to match /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/
      expect(payload.has_key?("tag")).to be false
      expect(payload["data"]).to eq "some data"
    end

    it "creates payload with tag" do
      value = "some data"
      payload_string = @controller.create_payload(value, "title")
      payload = JSON.parse(payload_string)
      expect(payload["tag"]).to eq "title"
      expect(payload["data"]).to eq "some data"
    end
  end

  describe "#status" do
    it "gives out status" do
      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      out = double
      @controller.out = out

      expect(out).to receive(:puts).with(/example.org/)
      expect(out).to receive(:puts).with(/987654321/)

      @controller.status
    end
  end

  describe "#plot" do
    it "plots pairs of date and value" do
      @controller.config_dir = given_directory do
        given_file("myer.config")
        given_file("secret-ticket-987654321.json")
      end

      expect(@controller).to receive(:read_items).and_return(['{"data":"[\"2014-06-03\",\"37\"]"}','{"data":"[\"2014-06-04\",\"39\"]"}'])

      expect_any_instance_of(Plot).to receive(:show)

      @controller.plot
    end
  end

  describe "register_user" do
    it "registers as user client" do
      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      stub_request(:post, "http://abc:def@example.org:4735/tokens").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"token":"1800927539516"}', :headers => {})

      stub_request(:post, "http://example.org:4735/register/1800927539516").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"user_id":"157610723","user_password":"626078090"}', :headers => {})

      expect(@controller.user_id).to be(nil)
      expect(@controller.user_password).to be(nil)

      @controller.register_user

      expect(@controller.user_id).to eq "157610723"
      expect(@controller.user_password).to eq "626078090"
    end
  end
end
