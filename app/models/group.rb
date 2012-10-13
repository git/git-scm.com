class Group
  include MongoMapper::Document
  key :version, String

  key :name, String
  many :function
end
