task :search_index => :environment do
  # BONSAI.clear
  version = Version.all.last
  puts version.name
  version.doc_versions.each do |docv|
    p docv.index
  end
end
