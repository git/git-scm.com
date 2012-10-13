require 'redcarpet'
require 'pp'

task 'library:import' => [:environment] do |t|
  file = 'HEAD.json'
  version = 'HEAD'
  docs = JSON.parse(IO.read(file), :symbolize_names => true)

  MongoMapper.connection.drop_database(MongoMapper.database.name)

  docs[:groups].each do |(group_name, _)|
    Group.create(:name => group_name, :function_ids => [], :version => version).save!
  end

  docs[:functions].each do |func_name, func|
    func[:name] = func_name
    func[:version] = version
    func[:examples] = func[:examples].to_a

    group = Group.where(:name => func[:group]).first
    func[:group] = group

    doc = Function.create(func)
    doc.save!

    group.function_ids << doc.id
    group.save!
  end

  Group.ensure_index([[:version, -1], [:name, 1]])
  Function.ensure_index([[:version, -1], [:name, 1]])
end
