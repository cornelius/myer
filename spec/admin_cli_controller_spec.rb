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

      @controller.write_state

      expect(File.read(File.join(config_dir,"myer.config"))).to eq(<<EOT
---
default_server: example.com
example.com:
  admin_id: '123'
  password: '456'
  default_bucket_id: '890'
EOT
      )
    end

    it "reads state from config file" do
      config_dir = given_directory do
        given_file "myer.config"
      end
      @controller.config_dir = config_dir

      @controller.read_state

      expect(@controller.server).to eq "example.org"
      expect(@controller.admin_id).to eq "abc"
      expect(@controller.password).to eq "def"
      expect(@controller.default_bucket_id).to eq "ghi"
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
      stub_request(:post, "http://abc:def@example.org:4735/data").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"bucket_id":"150479372"}', :headers => {})

      config_file_path = nil
      @controller.config_dir = given_directory do
        config_file_path = given_file("myer.config")
      end

      bucket_id = @controller.create_bucket
      expect(bucket_id).to eq "150479372"

      expect(@controller.default_bucket_id).to eq bucket_id

      config = YAML.load_file(config_file_path)
      expect(config["example.org"]["default_bucket_id"]).to eq bucket_id
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
      stub_request(:post, "http://abc:def@example.org:4735/data/309029630").
         with(:body => 'my data', :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => '{"item_id":"504885608","parent_id":"772806166"}', :headers => {})

      @controller.config_dir = given_directory do
        given_file("myer.config")
      end

      item_id = @controller.write_item("309029630", "my data")

      expect(item_id).to eq "504885608"
    end
  end
end
