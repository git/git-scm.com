class Function
  include MongoDoc

  def group_name
    @doc['group']
  end

  def group
    @group ||= Group.new(
      Function.collection.find('_id' => @doc['group'], 'version' => version))
  end
end
