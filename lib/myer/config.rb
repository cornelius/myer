module Myer
  module Config
    include XDG::BaseDir::Mixin

    def subdirectory
      "myer"
    end

    attr_accessor :config_dir

    attr_accessor :server
    attr_accessor :admin_id, :password, :default_bucket_id
    attr_accessor :user_id, :user_password

    def initialize_config
      @config_dir = config.home.to_s
    end

    def write_state
      FileUtils.mkdir_p(@config_dir)
      state = {
        "default_server" => server,
        server => {
          "admin_id" => admin_id, "password" => password
        }
      }
      state[server]["user_id"] = user_id if user_id
      state[server]["user_password"] = user_password if user_password
      if default_bucket_id
        state[server]["default_bucket_id"] = default_bucket_id
      end
      File.write(File.join(@config_dir, "myer.config"), state.to_yaml)
    end

    def read_state
      state = YAML.load_file(File.join(@config_dir, "myer.config"))

      self.server = state["default_server"]
      server_state = state[server]

      self.admin_id = server_state["admin_id"]
      self.password = server_state["password"]
      self.user_id = server_state["user_id"]
      self.user_password = server_state["user_password"]
      self.default_bucket_id = server_state["default_bucket_id"]
    end
  end
end
