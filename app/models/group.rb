class Group
  include MongoMapper::Document
  safe
  key :version, String

  key :name, String
  many :functions, :class_name => "Function", :in => :function_ids
end
