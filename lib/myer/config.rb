module Myer
  module Config
    include XDG::BaseDir::Mixin

    def subdirectory
      "myer"
    end

    attr_accessor :config_dir, :data_dir

    def initialize_config
      @config_dir = config.home.to_s
      @data_dir = data.home.to_s
    end

    def local_buckets_dir
      File.join(@data_dir, "buckets")
    end

    def local_csv_path(bucket_id)
      File.join(local_buckets_dir, bucket_id + ".csv")
    end

    def local_json_path(bucket_id)
      File.join(local_buckets_dir, bucket_id + ".json")
    end

    class ServerConfig
      attr_accessor :admin_id, :admin_password
      attr_accessor :user_id, :user_password
      attr_accessor :default_bucket_id

      def initialize(yaml)
        @admin_id = yaml["admin_id"]
        @admin_password = yaml["admin_password"]
        @user_id = yaml["user_id"]
        @user_password = yaml["user_password"]
        @default_bucket_id = yaml["default_bucket_id"]
      end
    end

    def default_server=(value)
      @config ||= {}
      @config["default_server"] = value
    end

    def default_server
      @config["default_server"]
    end

    def self.define_attribute(name)
      define_method(name.to_s) do
        return nil if !@config || !@config["servers"]
        @config["servers"][default_server][name.to_s]
      end

      define_method(name.to_s + "=") do |value|
        @config ||= {}
        @config["servers"] ||= {}
        @config["servers"][default_server] ||= {}
        @config["servers"][default_server][name.to_s] = value
      end
    end

    define_attribute :admin_id
    define_attribute :admin_password
    define_attribute :user_id
    define_attribute :user_password
    define_attribute :default_bucket_id

    def write_config
      FileUtils.mkdir_p(@config_dir)
      File.write(File.join(@config_dir, "myer.config"), @config.to_yaml)
    end

    def read_config
      config_file = File.join(@config_dir, "myer.config")
      return if !File.exist?(config_file)

      @config = YAML.load_file(config_file)

      @default_server = @config["default_server"]
    end

    def servers
      @config["servers"].keys
    end

    def server(name)
      return nil if !@config["servers"] || !@config["servers"].has_key?(name)
      ServerConfig.new(@config["servers"][name])
    end
  end
end
