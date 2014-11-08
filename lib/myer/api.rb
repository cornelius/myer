module MySelf
  class Api
    attr_accessor :server
    attr_accessor :user, :password

    def admin_register(pid)
      http = Net::HTTP.new(server, 4735)

      request = Net::HTTP::Post.new("/admin/register/#{pid}")

      response = http.request(request)

      if response.code != "200"
        raise "HTTP Error #{response.code} - #{response.body}"
      else
        json = JSON.parse(response.body)

        return json["admin_id"], json["password"]
      end
    end


    def admin_list_buckets
      http = Net::HTTP.new(server, 4735)

      request = Net::HTTP::Get.new("/admin/buckets")
      request.basic_auth(user, password)

      response = http.request(request)

      if response.code != "200"
        raise "HTTP Error #{response.code} - #{response.body}"
      else
        json = JSON.parse(response.body)

        return json
      end
    end

    def create_token
      http = Net::HTTP.new(server, 4735)

      path = "/tokens"
      request = Net::HTTP::Post.new(path)
      request.basic_auth(user, password)

      response = http.request(request)

      if response.code != "200"
        raise "#{path} HTTP Error #{response.code} - #{response.body}"
      else
        json = JSON.parse(response.body)

        return json["token"]
      end
    end

    def register(token)
      http = Net::HTTP.new(server, 4735)

      path = "/register/" + token
      request = Net::HTTP::Post.new(path)

      response = http.request(request)

      if response.code != "200"
        raise "#{path} HTTP Error #{response.code} - #{response.body}"
      else
        json = JSON.parse(response.body)

        return json["user_id"], json["user_password"]
      end
    end
  end
end
