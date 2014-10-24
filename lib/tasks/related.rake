require 'faraday'

# bundle exec rake related
CONTENT_SERVER  = ENV["CONTENT_SERVER"] || "http://localhost:3001"
UPDATE_TOKEN    = ENV["UPDATE_TOKEN"]

def http_client(url)
  @client ||= begin
    Faraday.new(url: url)
  end
end

def create_related_item(from, to)
  url = CONTENT_SERVER + "/related"
  params = {
    from_content: from,
    to_content:   to,
    token:        UPDATE_TOKEN
  }
  http_client(url).post url, params
end

desc "Generate the related sidebar content"
task :related => :environment do
  find_reference_links
  find_book_links

  # TODO: git-ref?
  # TODO: screencasts?
  # TODO: blog posts?

end

CMD_IGNORE = ['aware', 'binaries', 'ci', 'co', 'com', 'directory', 'feature',
         'gitolite', 'gitosis-init', 'installed', 'last', 'library', 'my',
         'mygrit', 'project', 'prune', 'rack', 'repository', 'stash-unapply',
         'tarball', 'that', 'user', 'visual', 'will', 'world', 'unstage']

# book content
#  - reference calls
def find_book_links
  aindex = {}
  book = Book.where(:code => 'en', :edition => 2).first
  book.sections.each do |section|
    content = section.html
    content.scan(/git (\-+[a-z\-=]+ )*([a-z][a-z\-]+)/) do |match|
      next if CMD_IGNORE.include? match[1]
      aindex[match[1]] ||= []
      aindex[match[1]] << section.id
    end
  end
  aindex.each do |command, ids|
    command = "git-#{command}"
    sec_ids = {}
    ids.each do |id|
      sec_ids[id] ||= 0
      sec_ids[id] += 1
    end
    sec_ids.each do |id, score|
      if section = Section.find(id)
        puts "linking #{section.title} with #{command}"
        from = ['book', section.title, section.slug, "/book/en/v#{section.book.edition}/#{section.slug}", score]
        to   = ['reference', command, command, "/docs/#{command}", score]
        create_related_item(from, to)
      end
    end
  end
end

# index all reference pages
#  - linked to/from other pages
def find_reference_links
  v = Version.latest_version
  v.doc_versions.each do |dv|
    f = dv.doc_file
    doc = dv.doc
    name = f.name

    matches = doc.plain.scan(/linkgit:(.*?)\[(\d)\]/)

    m = {}
    matches.each do |command, number|
      m[command] ||= 0
      m[command] += 1
    end
    related = m.sort { |a, b| b[1] <=> a[1] }[0, 5]

    related.each do |command, score|
      next if command == name
      doc_file = DocFile.with_includes.where(name: command).limit(1).first
      rdv = doc_file.doc_versions.latest_version rescue nil
      if rdv
        puts "linking #{name} with #{command}"
        from = ['reference', name, name, "/docs/#{name}", score]
        to   = ['reference', command, command, "/docs/#{command}", score]
        create_related_item(from, to)
      end
    end
  end
end
