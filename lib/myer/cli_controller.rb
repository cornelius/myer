class CliController
  include Myer::Config

  attr_accessor :out, :crypto

  def initialize
    @out = STDOUT
    initialize_config
    @crypto = Crypto.new
  end

  def api
    api = MySelf::Api.new
    api.server = server
    api.user = user_id
    api.password = user_password
    api
  end

  def track_clicks(mouse_id)
    XinputParser.new.track_clicks(mouse_id) do
      puts "CLICK"
    end
  end

  def create_bucket
    read_state

    bucket_id = api.create_bucket

    self.default_bucket_id = bucket_id

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

    return api.create_item(bucket_id, content)
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

    items = api.get_items(bucket_id)

    content_list = []
    items.each do |item|
      content = @crypto.decrypt(item.content)
      out.puts("#{item.id}: #{content}")
      content_list.push(content)
    end

    content_list
  end

  def read
    read_state
    read_items(default_bucket_id)
  end

  def create_payload(value, tag = nil)
    payload = {}
    payload["id"] = SecureRandom.hex
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
