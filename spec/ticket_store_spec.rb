require_relative "spec_helper"

include GivenFilesystemSpecHelpers

describe TicketStore do
  use_given_filesystem(:keep_files => true)

  before(:each) do
  end

  it "loads" do
    bucket_id = "12345678"

    ticket_dir = given_directory do
      ticket_path = given_file("secret-ticket-#{bucket_id}.json")
    end

    store = TicketStore.new(ticket_dir)
    ticket = store.load_ticket(bucket_id)

    expect(ticket.bucket_id).to eq bucket_id
    expect(ticket.key).to eq "secret key"
  end

  it "raises exception on load of invalid ticket" do
    expect {
      TicketStore.new.load_ticket(given_dummy_file)
    }.to raise_error
  end

  it "saves" do
    ticket_dir = given_directory

    bucket_id = "456789012"
    bucket_key = "geheim"

    store = TicketStore.new(ticket_dir)
    ticket = Ticket.new
    ticket.bucket_id = bucket_id
    ticket.key = bucket_key

    store.save_ticket(ticket)

    ticket_path = File.join(ticket_dir, "secret-ticket-#{bucket_id}.json")

    expect(File.read(ticket_path)).to eq(<<EOT
{"bucket_id":"456789012","key":"geheim"}
EOT
    )
    expect(File.stat(ticket_path).mode).to eq 0100600
  end
end
