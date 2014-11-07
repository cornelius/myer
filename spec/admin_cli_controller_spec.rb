require_relative "spec_helper.rb"

require "shared_examples_for_config"

include GivenFilesystemSpecHelpers

describe AdminCliController do
  use_given_filesystem

  before(:each) do
    @controller = AdminCliController.new
  end

  it_behaves_like "config"

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
