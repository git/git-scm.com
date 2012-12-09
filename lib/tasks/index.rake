require 'asciidoc'
require 'octokit'
require 'time'
require 'digest/sha1'

# fill in the db from a local git clone
task :preindex => :environment do
  ActiveRecord::Base.logger.level = Logger::WARN

  template_dir = File.join(Rails.root, 'templates')
  repo = ENV['GIT_REPO'] || 'gitster/git'
  rebuild = ENV['REBUILD_DOC']
  rerun = ENV['RERUN'] || false

  blob_content = Hash.new do |blobs, sha|
    content = Base64.decode64( Octokit.blob( repo, sha, :encoding => 'base64' ).content )
    blobs[sha] = content.encode( 'utf-8', :undef => :replace )
  end

  # find all tags
  tags = Octokit.tags( repo ).select { |tag| tag.name =~ /^v1[\d\.]+$/ }  # just get release tags

  if rebuild
    tags = tags.select { |t| t.name == rebuild }
    rerun = true
  end

  # for each tag, get a date and a list of file/shas
  tags.sort_by( &:name ).each do |tag|

    puts tag.name

    stag = Version.where(:name => tag.name.gsub('v','')).first
    next if stag && !rerun

    stag = Version.where(:name => tag.name.gsub('v','')).first_or_create

    # extract metadata
    commit_info = Octokit.commit( repo, tag.name )
    commit_sha = commit_info.sha
    tree_sha = commit_info.commit.tree.sha
    ts = Time.parse( commit_info.commit.committer.date )

    # save metadata
    puts "#{tag.name}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"
    stag.commit_sha = commit_sha
    stag.tree_sha = tree_sha
    stag.committed = ts
    stag.save

    # find all the doc entries
    tree_info = Octokit.tree( repo, tree_sha, :recursive => true )
    tag_files = tree_info.tree
    doc_files = tag_files.select { |ent| ent.path =~ /^Documentation\/(git.*|everyday|howto-index|user-manual)\.txt/ }

    puts "Found #{doc_files.size} entries"

    # Generate this tag's command list for includes
    puts "building command list"
    if cmd_file = tag_files.detect { |ent| ent.path == 'command-list.txt' }
      commands = blob_content[cmd_file.sha]
      cmd_list = commands.split( "\n" ).reject { |l| l =~ /^#/ }.inject( {} ) do |list, cmd|
        name, kind, attr = cmd.split( /\s+/ )
        list[kind] ||= []
        list[kind] << [name, attr]
        list
      end
    else
      cmd_list = {}
    end

    # Build virtual category include files for inclusion by actual checked-in files
    puts "building include files"
    categories = cmd_list.keys.inject({}) do |list, category|
      if category_file = tag_files.detect { |ent| ent.path == "Documentation/#{category}.txt" }
        links = cmd_list[category].map do |cmd, attr|
          if match = blob_content[category_file.sha].match( /NAME\n----\n\S+ - (.*)$/ )
            "linkgit:#{cmd}[1]::\n\t#{attr == 'deprecated' ? '(deprecated) ' : ''}#{match[1]}\n"
          end
        end

        list.merge!("cmds-#{category}.txt" => links.compact.join("\n"))
      else
        list
      end
    end

    doc_limit = ENV['ONLY_BUILD_DOC']
    doc_files = doc_files.select { |df| df.path =~ /#{doc_limit}/ } if doc_limit

    doc_files.each do |entry|
      path = File.basename( entry.path, '.txt' )
      file = DocFile.where(:name => path).first_or_create

      puts "   build: #{path}"

      content = blob_content[entry.sha]
      asciidoc = Asciidoc::Document.new(path, content) do |inc|
        if categories.has_key?(inc)
          categories[inc]
        else
          if match = inc.match(/^\.\.\/(.*)$/)
            git_path = match[1]
          else
            git_path = "Documentation/#{inc}"
          end

          if inc_file = tag_files.detect { |f| f.path == git_path }
            blob_content[inc_file.sha]
          else
            ''
          end
        end
      end
      asciidoc_sha = Digest::SHA1.hexdigest( asciidoc.source )

      doc = Doc.where( :blob_sha => asciidoc_sha ).first_or_create
      if rerun || !doc.plain || !doc.html
        doc.plain = asciidoc.source
        doc.html  = asciidoc.render( template_dir )
        doc.save
      end
      dv = DocVersion.where(:version_id => stag.id, :doc_file_id => file.id).first_or_create
      dv.doc_id = doc.id
      dv.save
    end

  end
  Rails.cache.write("latest-version", Version.latest_version.name)

  puts "Building author database"
  Octokit.contributors(repo).each do |c|
    name = Octokit.user(c.login).name
    author = Author.where(:name => name).first_or_create
    author.commit_count = c.contributions
    author.save
  end
end
