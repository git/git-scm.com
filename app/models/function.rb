class Function
  include MongoDoc

  def group
    @group ||= Group.new(
      Function.collection.find('_id' => @doc['group'], 'version' => version))
  end
end
