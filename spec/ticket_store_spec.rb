require_relative "spec_helper"

include GivenFilesystemSpecHelpers

describe TicketStore do
  use_given_filesystem

  before(:each) do
  end

  it "loads ticket for bucket id" do
    bucket_id = "12345678"

    ticket_dir = given_directory do
      ticket_path = given_file("secret-ticket-#{bucket_id}.json")
    end

    store = TicketStore.new(ticket_dir)
    ticket = store.load_ticket(bucket_id)

    expect(ticket.server).to eq "mycroft.example.org"
    expect(ticket.bucket_id).to eq bucket_id
    expect(ticket.key).to eq "secret key"
    expect(ticket.name).to eq "Test Data"
  end

  it "loads ticket from file" do
    bucket_id = "12345678"

    ticket_path = nil
    ticket_dir = given_directory do
      ticket_path = given_file("secret-ticket-#{bucket_id}.json")
    end

    store = TicketStore.new(ticket_dir)
    ticket = store.load_ticket_from_file(ticket_path)

    expect(ticket.bucket_id).to eq(bucket_id)
  end

  it "raises exception on load of invalid ticket" do
    ticket_file = ""
    ticket_dir = given_directory do
      ticket_file = given_dummy_file
    end

    expect {
      TicketStore.new(ticket_dir).load_ticket(ticket_file)
    }.to raise_error Myer::Error
  end

  it "raises exception if ticket doesn't exist" do
    expect {
      TicketStore.new(given_directory).load_ticket("nonexisting")
    }.to raise_error Myer::Error
  end

  it "loads all tickets" do
    ticket_dir = given_directory do
      given_file("secret-ticket-12345678.json")
      given_file("secret-ticket-987654321.json")
    end

    store = TicketStore.new(ticket_dir)
    tickets = store.tickets_per_server

    expect(tickets.size).to eq 2
    expect(tickets.keys).to eq ["mycroft.example.org", "localhost"]
    expect(tickets["mycroft.example.org"][0].bucket_id).to eq "12345678"
  end

  it "saves" do
    ticket_dir = given_directory

    server = "mycroft.example.org"
    bucket_id = "456789012"
    bucket_key = "geheim"
    bucket_name = "Test Data"

    store = TicketStore.new(ticket_dir)
    ticket = Ticket.new
    ticket.bucket_id = bucket_id
    ticket.key = bucket_key
    ticket.name = bucket_name
    ticket.server = server

    store.save_ticket(ticket)

    ticket_path = File.join(ticket_dir, "secret-ticket-#{bucket_id}.json")

    expect(File.read(ticket_path)).to eq(<<EOT
{"server":"mycroft.example.org","name":"Test Data","bucket_id":"456789012","key":"geheim"}
EOT
    )
    expect(File.stat(ticket_path).mode).to eq 0100600
  end

  describe "#has_ticket?" do
    before(:each) do
      ticket_dir = given_directory do
        given_file("secret-ticket-12345678.json")
      end

      @store = TicketStore.new(ticket_dir)
    end

    it "returns true if ticket exists" do
      expect(@store.has_ticket?("12345678")).to be(true)
    end

    it "returns false if ticket does not exist" do
      expect(@store.has_ticket?("xxxxxxxx")).to be(false)
    end
  end

  describe "ticket_path" do
    before(:each) do
      @ticket_dir = given_directory
      @store = TicketStore.new(@ticket_dir)
    end

    it "returns path for ticket" do
      ticket = Ticket.new
      ticket.bucket_id = "123"

      expect(@store.ticket_path(ticket)).
        to eq(File.join(@ticket_dir, "secret-ticket-123.json"))
    end

    it "returns path for bucket id" do
      expect(@store.ticket_path("123")).
        to eq(File.join(@ticket_dir, "secret-ticket-123.json"))
    end
  end
end
