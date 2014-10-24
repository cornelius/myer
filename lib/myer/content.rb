class Content
  class Item
    attr_accessor :id, :written_at, :tag, :data
  end

  attr_reader :title

  def initialize
    @items = []
  end

  def add(content)
    json = JSON.parse(content)

    item = Item.new
    item.id = json["id"]
    item.written_at = json["written_at"]
    item.tag = json["tag"]
    if item.tag == "title"
      @title = json["data"]
    else
      item.data = JSON.parse(json["data"])
      @items.push(item)
    end
  end

  def all
    @items
  end

  def write_as_csv(output_path)
    File.open(output_path, "w") do |file|
      @items.each do |item|
        file.puts(item.data.join(","))
      end
    end
  end
end
