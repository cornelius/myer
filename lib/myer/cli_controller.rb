class CliController
  include Myer::Config

  attr_accessor :out, :crypto

  def initialize
    @out = STDOUT
    initialize_config
    @crypto = Crypto.new
  end

  def track_clicks(mouse_id)
    XinputParser.new.track_clicks(mouse_id) do
      puts "CLICK"
    end
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
end
