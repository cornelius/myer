class AdminCliController

  include XDG::BaseDir::Mixin

  def subdirectory
    "myer"
  end

  attr_accessor :out, :crypto
  attr_accessor :config_dir
  attr_accessor :server
  attr_accessor :admin_id, :password, :default_bucket_id
  attr_accessor :user_id, :user_password

  def initialize
    @out = STDOUT
    @config_dir = config.home.to_s
    @crypto = Crypto.new
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
    request.basic_auth(user_id, user_password)

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      bucket_id = json["bucket_id"]

      self.default_bucket_id = bucket_id
    end

    ticket = Ticket.new
    ticket.bucket_id = bucket_id
    ticket.key = @crypto.generate_passphrase

    store = TicketStore.new(config_dir)
    store.save_ticket(ticket)

    write_state

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
        out.puts bucket_id + (bucket_id == default_bucket_id ? " (default)" : "")
      end
    end
  end

  def write_item(bucket_id, content)
    read_state

    http = Net::HTTP.new(server, 4735)

    path = "/data/#{bucket_id}"
    request = Net::HTTP::Post.new(path)
    request.basic_auth(user_id, user_password)
    request.body = content

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      item_id = json["item_id"]
    end

    item_id
  end

  def write_raw(content)
    read_state
    write_item(default_bucket_id, content)
  end

  def write(content)
    read_state

    store = TicketStore.new(config_dir)
    ticket = store.load_ticket(default_bucket_id)

    @crypto.passphrase = ticket.key

    encrypted_content = @crypto.encrypt(content)

    write_item(default_bucket_id, encrypted_content)
  end

  def read_items(bucket_id)
    read_state

    store = TicketStore.new(config_dir)
    ticket = store.load_ticket(default_bucket_id)

    @crypto.passphrase = ticket.key

    http = Net::HTTP.new(server, 4735)

    path = "/data/#{bucket_id}"
    request = Net::HTTP::Get.new(path)
    request.basic_auth(user_id, user_password)

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      inner_items = []

      json = JSON.parse(response.body)

      json.each do |item|
        item_id = item["item_id"]
        content = @crypto.decrypt(item["content"])
        inner_items.unshift(content)
        out.puts("#{item_id}: #{content}")
      end

      return inner_items
    end
  end

  def read
    read_state
    read_items(default_bucket_id)
  end

  def create_payload(value, tag = nil)
    payload = {}
    payload["id"] = rand(100000000).to_s
    payload["written_at"] = Time.now.utc.strftime("%FT%TZ")
    payload["tag"] = tag if tag
    payload["data"] = value.to_s
    JSON.generate(payload)
  end

  def write_value(value, tag = nil)
    write(create_payload(value, tag))
  end

  def write_pair(value1, value2)
    json = [ value1, value2 ]
    write_value(JSON.generate(json))
  end

  def status
    read_state

    out.puts "Server: #{server}"
    out.puts "Bucket: #{default_bucket_id}"
  end

  def plot
    read_state

    csv_file = Tempfile.new("myer_plot_data")
    content = Content.new

    inner_items = read
    inner_items.each do |inner_item|
      content.add(inner_item)
    end

    content.write_as_csv(csv_file.path)

    plot = Plot.new
    plot.show(csv_file.path)
  end

  def register_user
    read_state

    http = Net::HTTP.new(server, 4735)

    path = "/tokens"
    request = Net::HTTP::Post.new(path)
    request.basic_auth(admin_id, password)

    response = http.request(request)

    if response.code != "200"
      raise "#{path} HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      token = json["token"]
    end

    path = "/register/" + token
    request = Net::HTTP::Post.new(path)

    response = http.request(request)

    if response.code != "200"
      raise "#{path} HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      self.user_id = json["user_id"]
      self.user_password = json["user_password"]

      write_state
    end
  end
end
