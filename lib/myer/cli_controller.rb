class CliController
  include Myer::Config

  attr_accessor :out, :crypto

  def initialize
    @out = STDOUT
    initialize_config
    @crypto = Crypto.new
  end

  def api(server_name = default_server)
    api = MySelf::Api.new
    api.server = server_name
    if server(server_name)
      api.user = server(server_name).user_id
      api.password = server(server_name).user_password
    end
    api
  end

  def create_bucket(name)
    read_config

    bucket_id = api.create_bucket

    self.default_bucket_id = bucket_id

    ticket = Ticket.new
    ticket.server = default_server
    ticket.bucket_id = bucket_id
    ticket.key = @crypto.generate_passphrase
    ticket.name = name

    store = TicketStore.new(config_dir)
    store.save_ticket(ticket)

    write_config

    out.puts("Created new bucket and stored its secret ticket at #{store.ticket_path(ticket)}.")
    out.puts("You need this ticket to give other clients access to the bucket.")
    out.puts("Keep it safe and secret. Everybody who has the ticket can read the bucket data.")

    bucket_id
  end

  def create_token
    read_config

    token = api.create_token

    out.puts("Created token: #{token}")
    out.puts("Use this token to register another client, " +
             "e.g. with `myer register #{default_server} #{token}`.")

    token
  end

  def register(server_name, token)
    read_config

    self.default_server = server_name
    self.user_id, self.user_password = api(server_name).register(token)

    write_config
  end

  def write_item(bucket_id, content)
    read_config

    return api.create_item(bucket_id, content)
  end

  def write_raw(content)
    read_config
    write_item(default_bucket_id, content)
  end

  def write(content)
    read_config

    store = TicketStore.new(config_dir)
    ticket = store.load_ticket(default_bucket_id)

    @crypto.passphrase = ticket.key

    encrypted_content = @crypto.encrypt(content)

    write_item(default_bucket_id, encrypted_content)
  end

  def read_items(bucket_id)
    read_config

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
    read_config
    if !default_bucket_id || default_bucket_id.empty?
      raise Myer::Error.new("Default bucket id not set")
    end
    inner_items = read_items(default_bucket_id)

    FileUtils.mkdir_p(local_buckets_dir)
    csv_file = local_csv_path(default_bucket_id)
    json_file = local_json_path(default_bucket_id)
    content = Content.new

    inner_items.each do |inner_item|
      content.add(inner_item)
    end

    content.write_as_csv(csv_file)
    if content.type == "json"
      content.write_as_json(json_file)
    end

    inner_items
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

  def plot(dont_sync: false)
    read_config

    read unless dont_sync

    plot = Plot.new
    plot.show(local_csv_path(default_bucket_id))
  end

  def export(output_path)
    read_config

    content = Content.new
    inner_items = read
    inner_items.each do |inner_item|
      content.add(inner_item)
    end

    content.write_as_json(output_path)
  end

  def consume_ticket(ticket_source_path)
    read_config

    ticket_target_path = File.join(config_dir, File.basename(ticket_source_path))
    FileUtils.mv(ticket_source_path, ticket_target_path)
    store = TicketStore.new(config_dir)
    ticket = store.load_ticket_from_file(ticket_target_path)
    self.default_bucket_id = ticket.bucket_id

    write_config
  end

  def list_tickets(show_status: false)
    read_config

    store = TicketStore.new(config_dir)
    out.puts "Available Tickets:"
    store.tickets_per_server.each do |server_name,tickets|
      if show_status
        server_api = api(server_name)
        begin
          server_api.ping
          status = " [pings]"
        rescue StandardError => e
          status = " [ping error: #{e.message.chomp}]"
        end
      end
      out.puts "  Server '#{server_name}'#{status}:"
      tickets.each do |ticket|
        out.puts "    Bucket '#{ticket.name}' (#{ticket.bucket_id})"
      end
    end
  end
end
