module UniqueCollectionGenerator
  def self.generate(num_items)
    unique_list = []
    until unique_list.length >= num_items
      item = yield unique_list.length
      unique_list << item unless unique_list.include?(item)
    end
    unique_list
  end
end
