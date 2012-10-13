class Function
  include MongoMapper::Document
  key :version, String

  key :argline, String
  key :args, Array
  key :comments, String
  key :description, String
  key :file, String
  key :line, Integer
  key :lineto, Integer
  key :return, Hash
  key :sig, String
  key :type, String

  belongs_to :group
end
