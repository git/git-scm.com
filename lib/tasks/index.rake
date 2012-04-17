require 'asciidoc'
require 'octokit'
require 'time'

# fill in the db from a local git clone
task :preindex => :environment do
  template_dir = File.join(Rails.root, 'templates')
  repo = ENV['GIT_REPO'] || 'git/git'
  rerun = false

  # find all tags
  tags = Octokit.tags( repo ).select { |tag| tag.name =~ /^v1[\d\.]+$/ }  # just get release tags

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
    ts = Time.parse( commit_info.commit.committer.date ).to_i

    # save metadata
    puts "#{tag.name}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"
    stag.commit_sha = commit_sha
    stag.tree_sha = tree_sha
    stag.committed = ts
    stag.save

    # find all the doc entries
    tree_info = Octokit.tree( repo, tree_sha, :recursive => true )
    tag_files = tree_info.tree
    doc_files = tag_files.select { |ent| ent.path =~ /^Documentation\/(git.*|everyday|howto-index,user-manual)\.txt/ }

    puts "Found #{doc_files.size} entries"

    blob_content = Hash.new do |docs, sha|
      content = Base64.decode64( Octokit.blob( repo, sha, :encoding => 'base64' ).content )
      content.encode( 'utf-8', :undef => :replace )
    end

    # Generate this tag's command list for includes
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

    doc_files.each do |entry|
      path = File.basename( entry.path, '.txt' )
      file = DocFile.where(:name => path).first_or_create
      doc = Doc.where(:blob_sha => entry.sha).first_or_create
      if !doc.plain || !doc.html
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
        doc.plain = asciidoc.source
        doc.html  = asciidoc.render(template_dir)
        doc.save
      end
      DocVersion.where(:version_id => stag.id, :doc_id => doc.id, :doc_file_id => file.id).first_or_create
    end

  end
end

