class AdminCliController
  include Myer::Config

  attr_accessor :out

  def initialize
    @out = STDOUT
    initialize_config
  end

  def api(server_name = default_server)
    api = MySelf::Api.new
    api.server = server_name
    if server(server_name)
      api.user = server(server_name).admin_id
      api.password = server(server_name).admin_password
    end
    api
  end

  def register(server_name, pid)
    self.default_server = server_name
    self.admin_id, self.admin_password = api(server_name).admin_register(pid)

    write_state
  end

  def list_buckets
    read_state

    buckets = api.admin_list_buckets

    store = TicketStore.new(config_dir)
    buckets.each do |bucket_id|
      line = bucket_id + ": "
      ticket = store.load_ticket(bucket_id)
      if ticket
        line += ticket.name || "<no name>"
      else
        line += "<no ticket>"
      end
      if bucket_id == default_bucket_id
        line += " (default)"
      end
      out.puts line
    end
  end

  def delete_bucket(bucket_id)
    read_state

    api.admin_delete_bucket(bucket_id)
  end

  def status
    read_state

    out.puts "Default server: #{default_server}"
    out.puts "Default bucket: #{default_bucket_id}"
  end

  def register_user
    read_state

    token = api.create_token
    self.user_id, self.user_password = api.register(token)

    write_state
  end
end
