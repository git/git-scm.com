require 'asciidoctor'

# fill in the db from a local git clone
task :local_index => :environment do
  template_dir = File.join(Rails.root, 'templates')
  dir     = ENV["GIT_REPO"]
  rebuild = ENV['REBUILD_DOC']
  rerun   = ENV['RERUN'] || false

  Dir.chdir(dir) do
    # find all tags
    tags = `git tag | egrep 'v1|v2'`.strip.split("\n")
    tags = tags.select { |tag| tag =~ /v\d([\.\d])+$/ }  # just get release tags

    if rebuild
      tags = tags.select { |t| t == rebuild }
      rerun = true
    end

    # for each tag, get a date and a list of file/shas
    tags.sort.each do |tag|

      puts tag

      stag = Version.where(:name => tag.gsub('v','')).first
      next if stag && !rerun

      stag = Version.where(:name => tag.gsub('v','')).first_or_create

      # extract metadata
      commit_sha = `git rev-parse #{tag}`.chomp
      tree_sha = `git rev-parse #{tag}^{tree}`.chomp
      tagger = `git cat-file commit #{tag} | grep committer`.chomp.split(' ')
      tz = tagger.pop
      ts = tagger.pop
      ts = Time.at(ts.to_i)

      # save metadata
      puts "#{tag}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"
      stag.commit_sha = commit_sha
      stag.tree_sha = tree_sha
      stag.committed = ts
      stag.save

      # find all the doc entries
      entries = `git ls-tree #{tag}:Documentation`.strip.split("\n")
      tree = entries.map do |e|
        mode, type, sha, path = e.split(' ')
        [path, sha, type]
      end
      tree = tree.select { |t| t.first =~ /^(git.*|everyday|howto-index|user-manual|diff.*|fetch.*|merge.*|rev.*|pretty.*|pull.*)\.txt/ }

      puts "Found #{tree.size} entries"
      doc_limit = ENV['ONLY_BUILD_DOC']

      tree.each do |entry|
        path, sha, type = entry
        path = path.gsub('.txt', '')
        next if doc_limit && path !~ /#{doc_limit}/
        file = DocFile.where(:name => path).first_or_create

        puts "   build: #{path}"

        content = `git cat-file blob #{sha}`.chomp
        content.gsub!(/include::(\S+)\.txt/) do |line|
          line.gsub!("include::", "")
          `git cat-file blob #{tag}:Documentation/#{line}`
        end
        asciidoc = Asciidoctor::Document.new(content, templates_dir: template_dir)
        asciidoc_sha = Digest::SHA1.hexdigest( asciidoc.source )

        doc = Doc.where(:blob_sha => asciidoc_sha).first_or_create
        if rerun || !doc.plain || !doc.html
          html = asciidoc.render
          html.gsub!(/linkgit:(\S+)\[(\d+)\]/) do |line|
            x = /^linkgit:(\S+)\[(\d+)\]/.match(line)
            line = "<a href='/docs/#{x[1]}'>#{x[1]}[#{x[2]}]</a>"
          end
          doc.plain = asciidoc.source
          doc.html  = html
          doc.save
        end
        dv = DocVersion.where(:version_id => stag.id, :doc_file_id => file.id).first_or_create
        dv.doc_id = doc.id
        dv.save
      end

    end
  end
end
