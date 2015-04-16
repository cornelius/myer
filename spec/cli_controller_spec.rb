require_relative "spec_helper"

require "shared_examples_for_config"

include GivenFilesystemSpecHelpers

describe CliController do
  use_given_filesystem

  before(:each) do
    @controller = CliController.new
  end

  it_behaves_like "config"

  describe "#api" do
    it "provides user API" do
      @controller.config_dir = given_directory do
        given_file("myer.config", from: "myer-full.config")
      end
      @controller.read_config
      api = @controller.api

      expect(api.user).to eq "ddd"
      expect(api.password).to eq "ggg"
    end
  end

  describe "#create_bucket" do
    it "creates new bucket" do
      expected_bucket_id = "150479372"
      expect_any_instance_of(MySelf::Api).to receive(:create_bucket)
        .and_return(expected_bucket_id)

      config_file_path = nil
      @controller.config_dir = given_directory do
        config_file_path = given_file("myer.config", from: "myer-full.config")
      end

      ticket_name = "secret-ticket-#{expected_bucket_id}.json"
      ticket_file_path = File.join(@controller.config_dir, ticket_name)

      out = double
      expect(out).to receive(:puts).with(/#{ticket_name}/).at_least(:once)
      expect(out).to receive(:puts).at_least(:once)
      @controller.out = out

      bucket_id = @controller.create_bucket("Test Data")
      expect(bucket_id).to eq expected_bucket_id

      expect(@controller.default_bucket_id).to eq bucket_id

      config = YAML.load_file(config_file_path)
      expect(config["servers"]["example.org"]["default_bucket_id"]).to eq bucket_id

      json = JSON.parse(File.read(ticket_file_path))
      expect(json["server"]).to eq "example.org"
      expect(json["name"]).to eq "Test Data"
      expect(json["bucket_id"]).to eq expected_bucket_id
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

      @controller.read_config
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

  describe "#read" do
    it "gives an error when bucket is not set" do
      @controller.config_dir = given_directory

      expect {
        @controller.read
      }.to raise_error(Myer::Error)
    end

    it "writes read data to local csv file" do
      @controller.data_dir = given_directory
      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      expect(@controller).to receive(:read_items).
        with("987654321").
        and_return(['{"data":"2014-06-03,37"}','{"data":"2014-06-04,39"}'])

      @controller.read

      expect(File.read(File.join(@controller.data_dir, "buckets",
                                 @controller.default_bucket_id + ".csv"))).
        to eq <<EOT
2014-06-03,37
2014-06-04,39
EOT
    end

    it "writes read data to local json file if type is json" do
      @controller.data_dir = given_directory
      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      expect(@controller).to receive(:read_items).
        with("987654321").
        and_return(['{"tag":"type","data":"json"}','{"data":"[\"2014-06-03\",\"37\"]"}','{"data":"[\"2014-06-04\",\"39\"]"}'])

      @controller.read

      expected_json = '{"title":null,"data":[{"date":"2014-06-03","value":"37"},{"date":"2014-06-04","value":"39"}]}'

      expect(File.read(File.join(@controller.data_dir, "buckets",
                                 @controller.default_bucket_id + ".json"))).
        to eq(expected_json)
    end

    it "doesn't write read data to local json file if type is not json" do
      @controller.data_dir = given_directory
      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      expect(@controller).to receive(:read_items).
        with("987654321").
        and_return(['{"data":"2014-06-03,37"}','{"data":"2014-06-04,39"}'])

      @controller.read

      expect(File.exist?(File.join(@controller.data_dir, "buckets",
        @controller.default_bucket_id + ".json"))).to be(false)
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
    before(:each) do
      @controller.data_dir = given_directory
      @controller.config_dir = given_directory do
        given_file("myer.config")
        given_file("secret-ticket-987654321.json")
      end
    end

    it "reads data from server and plots pairs of date and value" do
      expect(@controller).to receive(:read_items).and_return(['{"data":"[\"2014-06-03\",\"37\"]"}','{"data":"[\"2014-06-04\",\"39\"]"}'])

      expect_any_instance_of(Plot).to receive(:show)

      @controller.plot
    end

    it "reads data from local file and plots it" do
      expect(@controller).to_not receive(:read_items)

      expect_any_instance_of(Plot).to receive(:show)

      @controller.plot(dont_sync: true)
    end
  end

  describe "#export" do
    it "exports read data as JSON" do
      @controller.data_dir = given_directory
      @controller.config_dir = given_directory do
        given_file("myer.config")
        given_file("secret-ticket-987654321.json")
      end

      output_path = File.join(given_directory, "export.json")

      expect(@controller).to receive(:read_items).and_return(['{"tag":"type","data":"json"}','{"data":"[\"2014-06-03\",\"37\"]"}','{"data":"[\"2014-06-04\",\"39\"]"}','{"data":"My Data","tag":"title"}'])

      @controller.export(output_path)

      expected_data = <<EOT
{"title":"My Data","data":[{"date":"2014-06-03","value":"37"},{"date":"2014-06-04","value":"39"}]}
EOT

      expect(File.read(output_path)).to eq(expected_data.chomp)
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

      expect(@controller.default_server).to eq server
      expect(@controller.user_id).to eq expected_user
      expect(@controller.user_password).to eq expected_password

      config = YAML.load_file(File.join(@controller.config_dir, "myer.config"))
      expect(config["servers"]["example.org"]["user_id"]).to eq expected_user
      expect(config["servers"]["example.org"]["user_password"]).to eq expected_password
    end
  end

  describe "#consume_ticket" do
    it "moves ticket to correct place" do
      ticket_name = "secret-ticket-12345678.json"
      ticket_source_path = given_file(ticket_name)
      @controller.config_dir = given_directory
      ticket_target_path = File.join(@controller.config_dir, ticket_name)
      ticket_content = File.read(ticket_source_path)

      expect(File.exist?(ticket_target_path)).to be(false)

      @controller.consume_ticket(ticket_source_path)

      expect(File.exist?(ticket_source_path)).to be(false)
      expect(File.read(ticket_target_path)).to eq ticket_content

      expect(@controller.default_bucket_id).to eq(YAML.load(ticket_content)["bucket_id"])
    end
  end

  describe "#list_tickets" do
    it "lists tickets" do
      @controller.config_dir = given_directory do
        given_file("secret-ticket-12345678.json")
        given_file("secret-ticket-987654321.json")
      end

      @controller.out = StringIO.new

      @controller.list_tickets

      expect(@controller.out.string).to eq <<EOT
Available Tickets:
  Server 'mycroft.example.org':
    Bucket 'Test Data' (12345678)
  Server 'localhost':
    Bucket 'Test Data' (987654321)
EOT
    end

    it "lists tickets with status" do
      stub_request(:get, "http://mycroft.example.org:4735/ping").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "{\"ping\":\"pong\"}", :headers => {})
      stub_request(:get, "http://localhost:4735/ping").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "broken", :headers => {})

      @controller.config_dir = given_directory do
        given_file("secret-ticket-12345678.json")
        given_file("secret-ticket-987654321.json")
        given_file("myer.config", from: "myer-full.config")
      end

      @controller.out = StringIO.new

      @controller.list_tickets(show_status: true)

      expect(@controller.out.string).to eq <<EOT
Available Tickets:
  Server 'mycroft.example.org' [pings]:
    Bucket 'Test Data' (12345678)
  Server 'localhost' [ping error: 757: unexpected token at 'broken']:
    Bucket 'Test Data' (987654321)
EOT
    end
  end
end
