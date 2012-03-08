# fill in the db from a local git clone
task :preindex => :environment do
  dir = ENV["GIT_REPO"]
  Dir.chdir(dir) do
    # find all tags
    tags = `git tag | grep v1`.strip.split("\n")
    tags = tags.select { |tag| tag =~ /v\d(\.\d)+$/ }  # just get release tags

    # for each tag, get a date and a list of file/shas
    tags.each do |tag|
      stag = Version.where(:name => tag).first_or_create

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
      tree = tree.select { |t| t.first =~ /.*\.txt/ }

      puts "Found #{tree.size} entries"

      tree.each do |entry|
        path, sha, type = entry
        path = path.gsub('.txt', '').gsub('v', '')
        file = DocFile.where(:name => path).first_or_create
        doc = Doc.where(:blob_sha => sha).first_or_create
        if !doc.plain
          content = `git cat-file blob #{sha}`.chomp
          doc.plain = content
          doc.save
        end
        DocVersion.where(:version_id => stag.id, :doc_id => doc.id, :doc_file_id => file.id).first_or_create
      end

    end
  end
end

