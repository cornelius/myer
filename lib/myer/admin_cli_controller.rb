class AdminCliController
  include Myer::Config

  attr_accessor :out

  def initialize
    @out = STDOUT
    initialize_config
  end

  def register(server, pid)
    http = Net::HTTP.new(server, 4735)

    request = Net::HTTP::Post.new("/admin/register/#{pid}")

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      self.server = server
      self.admin_id = json["admin_id"]
      self.password = json["password"]
    end

    write_state
  end

  def list_buckets
    read_state

    http = Net::HTTP.new(server, 4735)

    request = Net::HTTP::Get.new("/admin/buckets")
    request.basic_auth(admin_id, password)

    response = http.request(request)

    if response.code != "200"
      raise "HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      json.each do |bucket_id|
        out.puts bucket_id + (bucket_id == default_bucket_id ? " (default)" : "")
      end
    end
  end

  def status
    read_state

    out.puts "Server: #{server}"
    out.puts "Bucket: #{default_bucket_id}"
  end

  def register_user
    read_state

    http = Net::HTTP.new(server, 4735)

    path = "/tokens"
    request = Net::HTTP::Post.new(path)
    request.basic_auth(admin_id, password)

    response = http.request(request)

    if response.code != "200"
      raise "#{path} HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      token = json["token"]
    end

    path = "/register/" + token
    request = Net::HTTP::Post.new(path)

    response = http.request(request)

    if response.code != "200"
      raise "#{path} HTTP Error #{response.code} - #{response.body}"
    else
      json = JSON.parse(response.body)

      self.user_id = json["user_id"]
      self.user_password = json["user_password"]

      write_state
    end
  end
end
