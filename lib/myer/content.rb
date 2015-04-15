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

  def first
    at(0)
  end

  def at(index)
    @items.at(index)
  end

  def empty?
    @items.empty?
  end

  def length
    @items.length
  end

  def write_as_csv(output_path)
    File.open(output_path, "w") do |file|
      @items.each do |item|
        file.puts(item.data.join(","))
      end
    end
  end

  def write_as_json(output_path)
    json = {}
    json["title"] = title

    data_array = []
    @items.each do |item|
      data_item = {}
      data_item["date"] = item.data[0]
      data_item["value"] = item.data[1]

      data_array.push(data_item)
    end

    json["data"] = data_array

    File.open(output_path, "w") do |file|
      file.write(json.to_json)
    end
  end
end
