class TicketStore
  def initialize(ticket_dir)
    @ticket_dir = ticket_dir
  end

  def ticket_file_name(bucket_id)
    "secret-ticket-#{bucket_id}.json"
  end

  def load_ticket(bucket_id)
    file_path = File.join(@ticket_dir, ticket_file_name(bucket_id))
    json = JSON.parse(File.read(file_path))
    ticket = Ticket.new
    ticket.bucket_id = json["bucket_id"]
    ticket.key = json["key"]
    ticket
  end

  def save_ticket(ticket)
    file_path = File.join(@ticket_dir, ticket_file_name(ticket.bucket_id))
    json = { "bucket_id" => ticket.bucket_id, "key" => ticket.key }
    File.open(file_path, "w", 0600) do |f|
      f.write(JSON.generate(json))
      f.puts
    end
  end
end
