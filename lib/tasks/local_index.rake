require 'asciidoc'

# fill in the db from a local git clone
task :local_index => :environment do
  template_dir = File.join(Rails.root, 'templates')
  dir = ENV["GIT_REPO"]
  rebuild = ENV['REBUILD_DOC']
  rerun = ENV['RERUN'] || false

  Dir.chdir(dir) do
    # find all tags
    tags = `git tag | grep v1`.strip.split("\n")
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
      tree = tree.select { |t| t.first =~ /^(git.*|everyday|howto-index|user-manual)\.txt/ }

      puts "Found #{tree.size} entries"

      # generate this tag's command list for includes
      cmd_list = `git cat-file blob #{tag}:command-list.txt`.split("\n").reject{|l| l =~ /^#/}.inject({}) do |list, cmd|
        name, kind, attr = cmd.split(/\s+/)
        list[kind] ||= []
        list[kind] << [name, attr]
        list
      end
      categories = cmd_list.keys.inject({}) do |list, category|
        links = cmd_list[category].map do |cmd, attr|
          if match = `git cat-file blob #{tag}:Documentation/#{cmd}.txt`.match(/NAME\n----\n\S+ - (.*)$/)
            "linkgit:#{cmd}[1]::\n\t#{attr == 'deprecated' ? '(deprecated) ' : ''}#{match[1]}\n"
          end
        end

        list.merge!("cmds-#{category}.txt" => links.compact.join("\n"))
      end

      doc_limit = ENV['ONLY_BUILD_DOC']

      tree.each do |entry|
        path, sha, type = entry
        path = path.gsub('.txt', '')
        next if doc_limit && path !~ /#{doc_limit}/
        file = DocFile.where(:name => path).first_or_create

        puts "   build: #{path}"

        content = `git cat-file blob #{sha}`.chomp
        asciidoc = Asciidoc::Document.new(path, content) do |inc|
          if categories.has_key?(inc)
            categories[inc]
          else
            if match = inc.match(/^\.\.\/(.*)$/)
              git_path = match[1]
            else
              git_path = "Documentation/#{inc}"
            end

            `git cat-file blob #{tag}:#{git_path}`
          end
        end
        asciidoc_sha = Digest::SHA1.hexdigest( asciidoc.source )

        doc = Doc.where(:blob_sha => asciidoc_sha).first_or_create
        if rerun || !doc.plain || !doc.html
          doc.plain = asciidoc.source
          doc.html  = asciidoc.render(template_dir)
          doc.save
        end
        dv = DocVersion.where(:version_id => stag.id, :doc_file_id => file.id).first_or_create
        dv.doc_id = doc.id
        dv.save
      end

    end

    # get the list of authors by # of commits
    author_tag = tags.sort.last
    puts "Fetching author list for #{author_tag}"
    `git shortlog --no-merges -ns #{author_tag}`.each_line do |line|
      count, name = line.chomp.split(' ', 2)
      author = Author.where(:name => name).first_or_create
      author.commit_count = count
      author.save
    end
  end
end

