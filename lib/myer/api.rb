module MySelf
  class Api
    attr_accessor :server
    attr_accessor :user, :password

    def http_request
      http = Net::HTTP.new(server, 4735)

      request = yield

      response = http.request(request)

      if response.code != "200"
        raise "#{request.path} HTTP Error #{response.code} - #{response.body}"
      else
        return JSON.parse(response.body)
      end
    end

    def post(path, content = nil, auth_enabled = true)
      http_request do
        request = Net::HTTP::Post.new(path)
        request.basic_auth(user, password) if auth_enabled
        request.body = content if content
        request
      end
    end

    def get(path)
      http_request do
        request = Net::HTTP::Get.new(path)
        request.basic_auth(user, password)
        request
      end
    end

    def admin_register(pid)
      json = post("/admin/register/#{pid}",nil,false)
      return json["admin_id"], json["password"]
    end

    def admin_list_buckets
      get("/admin/buckets")
    end

    def create_token
      json = post("/tokens")
      return json["token"]
    end

    def register(token)
      json = post("/register/" + token, nil, false)
      return json["user_id"], json["user_password"]
    end

    def create_bucket
      json = post("/data")
      return json["bucket_id"]
    end

    def create_item(bucket_id, content)
      json = post("/data/#{bucket_id}", content)
      return json["item_id"]
    end

    def get_items(bucket_id)
      json = get("/data/#{bucket_id}")

      inner_items = []

      json.each do |json_item|
        item = OpenStruct.new
        item.id = json_item["item_id"]
        item.content = json_item["content"]
        inner_items.unshift(item)
      end

      return inner_items
    end
  end
end
