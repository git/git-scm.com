require 'redcarpet'
require 'pp'

task 'library:import' => [:environment] do |t|
  file = 'HEAD.json'
  version = 'HEAD'
  docs = JSON.parse(IO.read(file), :symbolize_names => true)

  docs[:groups].each do |(group_name, group)|
    Group.create(:name => group_name, :functions => group, :version => version).save!
  end

  docs[:functions].each do |func_name, func|
    func[:name] = func_name
    func[:version] = version
    func[:examples] = func[:examples].to_a
    func[:group] = Group.where(:group => func[:group]).first
    Function.create(func).save!
  end
end
