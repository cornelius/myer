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
      expect_any_instance_of(MySelf::Api).to receive(:create_bucket)
        .and_return("150479372")

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
      expect_any_instance_of(MySelf::Api).to receive(:create_item)
        .with("309029630", "my data")
        .and_return("504885608")

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
      items = [
        OpenStruct.new(id: "271086077", content: "my data"),
        OpenStruct.new(id: "263800370", content: "more data")
      ]

      expect_any_instance_of(MySelf::Api).to receive(:get_items).with(bucket_id)
        .and_return(items)

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
      @controller.config_dir = given_directory do
        given_file("myer.config")
        given_file("secret-ticket-987654321.json")
      end

      value = 42

      expect(@controller).to receive(:write_item)
      @controller.write_value(value)
    end
  end

  describe "#write_pair" do
    it "writes value pair" do
      @controller.config_dir = given_directory do
        given_file("myer.config")
        given_file("secret-ticket-987654321.json")
      end

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

  describe "#create_token" do
    it "creates token" do
      @controller.config_dir = given_directory do
        given_file("myer.config", from: "myer-full.config")
      end

      expected_token = "12345677890"
      expect_any_instance_of(MySelf::Api).to receive(:create_token)
        .and_return(expected_token)

      out = double
      expect(out).to receive(:puts).with(/#{expected_token}/).at_least(:once)
      @controller.out = out

      token = @controller.create_token

      expect(token).to eq expected_token
    end
  end

  describe "#register" do
    it "registers user client" do
      @controller.config_dir = given_directory

      token = "12342"
      server = "example.org"
      expected_user = "xxx"
      expected_password = "yyy"
      expect_any_instance_of(MySelf::Api).to receive(:register)
        .with(token)
        .and_return([expected_user, expected_password])

      @controller.register(server, token)

      expect(@controller.server).to eq server
      expect(@controller.user_id).to eq expected_user
      expect(@controller.user_password).to eq expected_password

      config = YAML.load_file(File.join(@controller.config_dir, "myer.config"))
      expect(config["example.org"]["user_id"]).to eq expected_user
      expect(config["example.org"]["user_password"]).to eq expected_password
    end
  end
end
