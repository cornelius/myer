class TicketStore
  def initialize(ticket_dir)
    @ticket_dir = ticket_dir
  end

  def ticket_file_name(bucket_id)
    "secret-ticket-#{bucket_id}.json"
  end

  def ticket_path(ticket)
    File.join(@ticket_dir, ticket_file_name(ticket.bucket_id))
  end

  def load_ticket(bucket_id)
    ticket = Ticket.new
    ticket.bucket_id = bucket_id
    begin
      ticket_content = File.read(ticket_path(ticket))
    rescue Errno::ENOENT
      return nil
    end
    json = JSON.parse(ticket_content)
    if json["bucket_id"] != bucket_id
      raise "Invalid ticket #{ticket_path(ticket)}. File name doesn't match bucket id"
    end
    ticket.key = json["key"]
    ticket.name = json["name"]
    ticket
  end

  def load_ticket_from_file(ticket_path)
    json = JSON.parse(File.read(ticket_path))
    ticket = Ticket.new
    ticket.bucket_id = json["bucket_id"]
    ticket.key = json["key"]
    ticket.name = json["name"]
    ticket
  end

  def save_ticket(ticket)
    json = { "name" => ticket.name, "bucket_id" => ticket.bucket_id,
             "key" => ticket.key }
    File.open(ticket_path(ticket), "w", 0600) do |f|
      f.write(JSON.generate(json))
      f.puts
    end
  end
end
