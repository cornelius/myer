require_relative "spec_helper"

require "shared_examples_for_config"

include GivenFilesystemSpecHelpers

describe CliController do
  use_given_filesystem

  before(:each) do
    @controller = CliController.new
  end

  it_behaves_like "config"
  
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
end
