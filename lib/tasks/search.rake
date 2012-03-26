task :search_index => :environment do
  # BONSAI.clear
  Version.all.each do |version|
    puts version.name
    version.doc_versions.each do |docv|
      file = docv.doc_file
      doc = docv.doc
      data = {
        'name' => file.name,
        'description' => file.description,
        'blob_sha' => doc.blob_sha,
        'text' => doc.plain,
      }
      BONSAI.add 'doc', file.name, data
    end
  end
end
