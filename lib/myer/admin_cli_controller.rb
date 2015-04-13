class AdminCliController
  include Myer::Config

  attr_accessor :out

  def initialize
    @out = STDOUT
    initialize_config
  end

  def api
    api = MySelf::Api.new
    api.server = server
    api.user = admin_id
    api.password = password
    api
  end

  def register(server, pid)
    self.server = server
    self.admin_id, self.password = api.admin_register(pid)

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

    out.puts "Server: #{server}"
    out.puts "Bucket: #{default_bucket_id}"
  end

  def register_user
    read_state

    token = api.create_token
    self.user_id, self.user_password = api.register(token)

    write_state
  end
end
