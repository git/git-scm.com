require 'redcarpet'
require 'pp'

def import_file(file, version)
  docs = JSON.parse(IO.read(file), :symbolize_names => true)

  docs[:groups].each do |(group_name, functions)|
    Group.create(:_id => group_name, :functions => functions, :version => version)
  end

  docs[:functions].each do |func_name, func|
    func[:_id] = func_name
    func[:version] = version
    func[:examples] = func[:examples].to_a
    doc = Function.create(func)
  end
end

task 'library:import' => [:environment] do |t|
  db = Rails.configuration.mongo_db
  db.connection.drop_database(db.name)

  versions = []

  Dir.glob('library-data/*.json') do |json_file|
    version = File.basename(json_file, '.json')
    import_file(json_file, version)
    versions << version
  end

  db['library_data'].insert(:_id => 'versions', :numbers => versions)
end
