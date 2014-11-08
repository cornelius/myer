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

      expect_any_instance_of(MySelf::Api).to receive(:admin_register).with("1234")
        .and_return(["181504088", "683271947"])

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
  end

  describe "#list_buckets" do
    it "lists existing buckets" do
      expect_any_instance_of(MySelf::Api).to receive(:admin_list_buckets)
        .and_return(["150479372","309029630"])

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

      token = "1800927539516"
      expect_any_instance_of(MySelf::Api).to receive(:create_token)
        .and_return(token)
      expect_any_instance_of(MySelf::Api).to receive(:register).with(token)
        .and_return(["123","456"])

      expect(@controller.user_id).to be(nil)
      expect(@controller.user_password).to be(nil)

      @controller.register_user

      expect(@controller.user_id).to eq "123"
      expect(@controller.user_password).to eq "456"
    end
  end
end
