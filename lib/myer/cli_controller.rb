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

  def create_bucket(name)
    read_state

    bucket_id = api.create_bucket

    self.default_bucket_id = bucket_id

    ticket = Ticket.new
    ticket.server = server
    ticket.bucket_id = bucket_id
    ticket.key = @crypto.generate_passphrase
    ticket.name = name

    store = TicketStore.new(config_dir)
    store.save_ticket(ticket)

    write_state

    out.puts("Created new bucket and stored its secret ticket at #{store.ticket_path(ticket)}.")
    out.puts("You need this ticket to give other clients access to the bucket.")
    out.puts("Keep it safe and secret. Everybody who has the ticket can read the bucket data.")

    bucket_id
  end

  def create_token
    read_state

    token = api.create_token

    out.puts("Created token: #{token}")
    out.puts("Use this token to register another client, " +
             "e.g. with `myer register #{server} #{token}`.")

    token
  end

  def register(server, token)
    read_state

    self.server = server
    self.user_id, self.user_password = api.register(token)

    write_state
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
    if !default_bucket_id || default_bucket_id.empty?
      raise Myer::Error.new("Default bucket id not set")
    end
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

  def export(output_path)
    read_state

    content = Content.new
    inner_items = read
    inner_items.each do |inner_item|
      content.add(inner_item)
    end

    content.write_as_json(output_path)
  end

  def consume_ticket(ticket_source_path)
    read_state

    ticket_target_path = File.join(config_dir, File.basename(ticket_source_path))
    FileUtils.mv(ticket_source_path, ticket_target_path)
    store = TicketStore.new(config_dir)
    ticket = store.load_ticket_from_file(ticket_target_path)
    self.default_bucket_id = ticket.bucket_id

    write_state
  end

  def list_tickets
    store = TicketStore.new(config_dir)
    out.puts "Available Tickets:"
    store.tickets_per_server.each do |server,tickets|
      out.puts "  Server '#{server}':"
      tickets.each do |ticket|
        out.puts "    Bucket '#{ticket.name}' (#{ticket.bucket_id})"
      end
    end
  end
end
