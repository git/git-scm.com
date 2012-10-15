# MongoDoc, the ghetto Mongo Mapper
module MongoDoc
  module ClassMethods
    def find(id, version = 'HEAD')
      return nil unless doc = self.collection.find("name" => id, 'version' => version).first
      self.new(doc)
    end

    def all(version = 'HEAD')
      self.collection.find('version' => version).map { |doc| self.new(doc) }
    end

    def collection
      Rails.configuration.mongo_db[self.name.downcase.pluralize]
    end

    def create(doc)
      self.collection.insert(doc)
    end

  end

  def initialize(doc)
    @doc = doc
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def method_missing(meth, *args, &block)
    @doc[meth.to_s]
  end

  attr_reader :doc
end
