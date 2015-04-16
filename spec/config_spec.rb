require_relative "spec_helper.rb"

include GivenFilesystemSpecHelpers

class MyConfig
  include Myer::Config
end

describe Myer::Config do
  use_given_filesystem

  describe "#local_csv_path" do
    before(:each) do
      @config = MyConfig.new
      @config.config_dir = given_directory
    end

    it "constructs path from bucket id" do
      @config.data_dir = given_directory

      expect(@config.local_csv_path("x7326")).
        to eq(File.join(@config.data_dir, "buckets/x7326.csv"))
    end
  end

  describe "#local_json_path" do
    before(:each) do
      @config = MyConfig.new
      @config.config_dir = given_directory
    end

    it "constructs path from bucket id" do
      @config.data_dir = given_directory

      expect(@config.local_json_path("x7326")).
        to eq(File.join(@config.data_dir, "buckets/x7326.json"))
    end
  end

  describe "#write_config" do
    before(:each) do
      @config = MyConfig.new
      @config.config_dir = given_directory
    end

    describe "with one server" do
      it "writes config" do
        @config.default_server = "example.org"

        @config.admin_id = "abc"
        @config.admin_password = "def"
        @config.user_id = "ddd"
        @config.user_password = "ggg"
        @config.default_bucket_id = "987654321"

        @config.write_config

        expect(File.read(File.join(@config.config_dir, "myer.config"))).
          to eq(File.read(test_data_path("myer-full.config")))
      end
    end
  end

  describe "#read_config" do
    describe "with one server" do
      before(:each) do
        @config = MyConfig.new
        @config.config_dir = given_directory do
          given_file("myer.config", from: "myer-full.config")
        end

        @config.read_config
      end

      it "reads config" do
        server = @config.server(@config.default_server)
        expect(server.admin_id).to eq "abc"
        expect(server.admin_password).to eq "def"
        expect(server.user_id).to eq "ddd"
        expect(server.user_password).to eq "ggg"
        expect(server.default_bucket_id).to eq "987654321"
      end

      it "reads default server" do
        expect(@config.default_server).to eq "example.org"
      end
    end

    describe "with multiple servers" do
      before(:each) do
        @config = MyConfig.new
        @config.config_dir = given_directory do
          given_file("myer.config", from: "myer-multiple.config")
        end

        @config.read_config
      end

      it "reads list of servers" do
        expect(@config.servers).to eq ["example.org", "localhost"]
      end

      it "returns nil, when server does not exist" do
        expect(@config.server("whatever")).to be_nil
      end

      it "reads config of one" do
        server = @config.server("example.org")
        expect(server.admin_id).to eq "one_admin_id"
        expect(server.admin_password).to eq "one_admin_password"
        expect(server.user_id).to eq "one_user_id"
        expect(server.user_password).to eq "one_user_password"
        expect(server.default_bucket_id).to eq "one_default_bucket"
      end

      it "reads config of two" do
        server = @config.server("localhost")
        expect(server.admin_id).to eq "two_admin_id"
        expect(server.admin_password).to eq "two_admin_password"
        expect(server.user_id).to eq "two_user_id"
        expect(server.user_password).to eq "two_user_password"
        expect(server.default_bucket_id).to eq "two_default_bucket"
      end

      it "reads default server" do
        expect(@config.default_server).to eq "example.org"
      end
    end
  end
end
