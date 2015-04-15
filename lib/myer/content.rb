class Content
  class Item
    attr_accessor :id, :written_at, :tag

    def initialize(container)
      @container = container
    end

    def data=(value)
      @data = value
    end

    def data
      if @container.type == "json"
        JSON.parse(@data)
      else
        @data
      end
    end
  end

  attr_reader :title, :type

  def initialize
    @items = []
  end

  def add(content)
    json = JSON.parse(content)

    item = Item.new(self)
    item.id = json["id"]
    item.written_at = json["written_at"]
    item.tag = json["tag"]
    if item.tag == "title"
      @title = json["data"]
    elsif item.tag == "type"
      @type = json["data"]
    else
      item.data = json["data"]
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
        if type == "json"
          file.puts(item.data.join(","))
        else
          file.puts(item.data)
        end
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
