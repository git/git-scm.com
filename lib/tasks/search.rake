task :search_clear => :environment do
  # BONSAI.clear
  Tire.index ELASTIC_SEARCH_INDEX do
    delete
    create
  end
end

task :search_index => :environment do
  version = Version.latest_version
  puts version.name
  version.doc_versions.each do |docv|
    p docv.index
  end
end

task :search_index_book => :environment do
  book = Book.where(:code => 'en', :edition => 2).first
  book.sections.each do |sec|
    sec.index
  end
end
