task :search_index => :environment do
  # BONSAI.clear
  version = Version.all.last
  puts version.name
  version.doc_versions.each do |docv|
    p docv.index
  end
end

require 'pp'
task :search_index_book => :environment do
  book = Book.where(:code => 'en', :edition => 2).first
  book.sections.each do |sec|
    sec.index
  end
end
