# rubocop:disable Style/FrozenStringLiteralComment

task search_clear: :environment do
  # BONSAI.clear
  client = ElasticClient.instance

  if client.indices.exists? index: ELASTIC_SEARCH_INDEX
    client.indices.delete index: ELASTIC_SEARCH_INDEX
  end

  client.indices.create index: ELASTIC_SEARCH_INDEX

end

task search_index: :environment do
  version = Version.latest_version
  puts version.name
  version.doc_versions.each do |docv|
    p docv.index
  end
end

task search_index_book: :environment do
  book = Book.where(code: "en", edition: 2).first
  book.sections.each do |sec|
    sec.index
  end
end
