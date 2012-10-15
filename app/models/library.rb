class Library

  def self.collection
    Rails.configuration.mongo_db['library_data']
  end

  def self.versions
    @@versions ||= collection.find('_id' => 'versions').first['numbers']
  end
end
