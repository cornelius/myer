shared_examples "config" do
  describe "remembers state" do
    it "writes state to config file" do
      config_dir = File.join(given_directory, "subdir")
      @controller.config_dir = config_dir

      @controller.default_server = "example.com"
      @controller.admin_id = "123"
      @controller.admin_password = "456"
      @controller.user_id = "abc"
      @controller.user_password = "xyz"
      @controller.default_bucket_id = "890"

      @controller.write_state

      expect(File.read(File.join(config_dir,"myer.config"))).to eq(<<EOT
---
default_server: example.com
servers:
  example.com:
    admin_id: '123'
    admin_password: '456'
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

      expect(@controller.default_server).to eq "example.org"
      server = @controller.server(@controller.default_server)
      expect(server.admin_id).to eq "abc"
      expect(server.admin_password).to eq "def"
      expect(server.user_id).to eq "ddd"
      expect(server.user_password).to eq "ggg"
      expect(server.default_bucket_id).to eq "987654321"
    end
  end
end
