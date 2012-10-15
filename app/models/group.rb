class Group
  include MongoDoc

  def function_names
    @doc['functions']
  end

  def functions
    @functions ||= Function.collection.find(
      'group' => self.name, 'version' => self.version).map { |f| Function.new(f) }
  end

  def length
    @doc['functions'].size
  end

  alias_method :size, :length
end
