class AdminCliController

  include XDG::BaseDir::Mixin

  def subdirectory
    "myer"
  end

  attr_accessor :out
  attr_accessor :config_dir
  attr_accessor :server
  attr_accessor :admin_id, :password

  def initialize
    @out = STDOUT
    @config_dir = config.home.to_s
  end

  def write_state
    FileUtils.mkdir_p(@config_dir)
    state = {
      "default_server" => server,
      server => { "admin_id" => admin_id, "password" => password }
    }
    File.write(File.join(@config_dir, "myer.config"), state.to_yaml)
  end

  def read_state
    state = YAML.load_file(File.join(@config_dir, "myer.config"))

    self.server = state["default_server"]
    server_state = state[server]

    self.admin_id = server_state["admin_id"]
    self.password = server_state["password"]
  end

  def register(server, pid)
    http = Net::HTTP.new(server, 4735)

    request = Net::HTTP::Post.new("/admin/register/#{pid}")

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      self.server = server
      self.admin_id = json["admin_id"]
      self.password = json["password"]
    end

    write_state
  end

  def create_bucket
    read_state

    http = Net::HTTP.new(server, 4735)

    request = Net::HTTP::Post.new("/data")
    request.basic_auth(admin_id, password)

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      bucket_id = json["bucket_id"]
    end

    bucket_id
  end

  def list_buckets
    read_state

    http = Net::HTTP.new(server, 4735)

    request = Net::HTTP::Get.new("/admin/buckets")
    request.basic_auth(admin_id, password)

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      json.each do |bucket_id|
        out.puts bucket_id
      end
    end
  end

end
