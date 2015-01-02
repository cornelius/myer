require_relative "spec_helper.rb"

describe TestCliController do
  use_given_filesystem

  before(:each) do
    @controller = TestCliController.new
  end

  describe "#full" do
    it "executes" do
      server = "example.org"
      pin = "1234"

      admin_id = "dhdhdh"
      admin_password = "373737"

      body = "{\"admin_id\":\"#{admin_id}\",\"password\":\"#{admin_password}\"}"
      stub_request(:post, "http://#{server}:4735/admin/register/#{pin}").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => body, :headers => {})

      token = "1t1t2t34uu5u5"

      body = "{\"token\":\"#{token}\"}"
      stub_request(:post, "http://#{admin_id}:#{admin_password}@#{server}:4735/tokens").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => body, :headers => {})

      user_id = "2458383"
      user_password = "sdfjksldfj"

      body = "{\"user_id\":\"#{user_id}\",\"user_password\":\"#{user_password}\"}"
      stub_request(:post, "http://#{server}:4735/register/#{token}").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => body, :headers => {})

      bucket_id = "123455"

      body = "{\"bucket_id\":\"#{bucket_id}\"}"
      stub_request(:post, "http://#{user_id}:#{user_password}@#{server}:4735/data").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => body, :headers => {})

      content = "octopus"

      item_id = "123556"
      parent_id = "49494"

      body = "{\"item_id\":\"#{item_id}\",\"parent_id\":\"#{parent_id}\"}"
      stub_request(:post, "http://#{user_id}:#{user_password}@#{server}:4735/data/#{bucket_id}").
        with(:body => content, :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => body, :headers => {})

      body = <<EOT
[
  {"item_id":"#{item_id}","parent_id":"","content":"#{content}"}
]
EOT

      stub_request(:get, "http://#{user_id}:#{user_password}@#{server}:4735/data/#{bucket_id}").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => body, :headers => {})

      @controller.out = double

      expect(@controller.out).to receive(:puts).with("Full acceptance test passed")

      @controller.full(server, pin)
    end
  end
end
