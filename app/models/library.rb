class Library

  def self.collection
    Rails.configuration.mongo_db['library_data']
  end

  def self.versions
    @@versions ||= begin
      col = collection.find('_id' => 'versions').first
      col ? col['numbers'] : []
    end
  end
end
