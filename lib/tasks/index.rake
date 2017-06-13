require 'asciidoctor'
require 'octokit'
require 'time'
require 'digest/sha1'

# fill in the db from a local git clone
task :preindex => :environment do
  ActiveRecord::Base.logger.level = Logger::WARN

  Octokit.auto_paginate = true
  @octokit = Octokit::Client.new(:login => ENV['API_USER'], :password => ENV['API_PASS'])

  repo = ENV['GIT_REPO'] || 'gitster/git'
  rebuild = ENV['REBUILD_DOC']
  rerun = ENV['RERUN'] || false

  blob_content = Hash.new do |blobs, sha|
    content = Base64.decode64( @octokit.blob( repo, sha, :encoding => 'base64' ).content )
    blobs[sha] = content.encode( 'utf-8', :undef => :replace )
  end

  # find all tags
  tags = @octokit.tags( repo ).select { |tag| !tag.nil? && tag.name =~ /v\d([\.\d])+$/ }  # just get release tags

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
    commit_info = @octokit.commit( repo, tag.name )
    commit_sha = commit_info.sha
    tree_sha = commit_info.commit.tree.sha
    # ts = Time.parse( commit_info.commit.committer.date )
    ts = commit_info.commit.committer.date
    # save metadata
    puts "#{tag.name}: #{ts}, #{commit_sha[0, 8]}, #{tree_sha[0, 8]}"
    stag.commit_sha = commit_sha
    stag.tree_sha = tree_sha
    stag.committed = ts
    stag.save

    # find all the doc entries
    tree_info = @octokit.tree( repo, tree_sha, :recursive => true )
    tag_files = tree_info.tree
    doc_files = tag_files.select { |ent| ent.path =~ /^Documentation\/(git.*|everyday|howto-index|user-manual|diff.*|fetch.*|merge.*|rev.*|pretty.*|pull.*)\.txt/ }

    puts "Found #{doc_files.size} entries"

    doc_limit = ENV['ONLY_BUILD_DOC']
    doc_files = doc_files.select { |df| df.path =~ /#{doc_limit}/ } if doc_limit

    # generate command-list content
    categories = {}
    if cmd_list_file = tag_files.detect { |ent| ent.path == "command-list.txt" }
      cmd_list = blob_content[cmd_list_file.sha].match(/(### command list.*|# command name.*)/m)[0].split("\n").reject{|l| l =~ /^#/}.inject({}) do |list, cmd|
        name, kind, attr = cmd.split(/\s+/)
        list[kind] ||= []
        list[kind] << [name, attr]
        list
      end

      categories = cmd_list.keys.inject({}) do |list, category|
        links = cmd_list[category].map do |cmd, attr|
          if cmd_file = tag_files.detect { |ent| ent.path == "Documentation/#{cmd}.txt" }
            if match = blob_content[cmd_file.sha].match(/NAME\n----\n\S+ - (.*)$/)
              "linkgit:#{cmd}[1]::\n\t#{attr == 'deprecated' ? '(deprecated) ' : ''}#{match[1]}\n"
            end
          end
        end
        list.merge!("cmds-#{category}.txt" => links.compact.join("\n"))
      end
    end

    def expand!(content, tag_files, blob_content, categories)
      content.gsub!(/include::(\S+)\.txt/) do |line|
        line.gsub!("include::","")
        if categories[line]
          new_content = categories[line]
        else
          content_file = tag_files.detect { |ent| ent.path == "Documentation/#{line}" }
          if content_file
              new_content = blob_content[content_file.sha]
          end
        end

        if new_content
          expand!(new_content, tag_files, blob_content, categories)
        end
      end
      return content
    end

    doc_files.each do |entry|
      path = File.basename( entry.path, '.txt' )
      file = DocFile.where(:name => path).first_or_create

      puts "   build: #{path}"

      content = blob_content[entry.sha]
      expand!(content, tag_files, blob_content, categories)
      asciidoc = Asciidoctor::Document.new(content, attributes: {'sectanchors' => ''})
      asciidoc_sha = Digest::SHA1.hexdigest( asciidoc.source )
      doc = Doc.where( :blob_sha => asciidoc_sha ).first_or_create
      if rerun || !doc.plain || !doc.html
        html = asciidoc.render
        html.gsub!(/linkgit:(\S+)\[(\d+)\]/) do |line|
          x = /^linkgit:(\S+)\[(\d+)\]/.match(line)
          line = "<a href='/docs/#{x[1]}'>#{x[1]}[#{x[2]}]</a>"
        end
        #HTML anchor on hdlist1 (i.e. command options)
        html.gsub!(/<dt class="hdlist1">(.*?)<\/dt>/) do |m|
          text = $1.tr('^A-Za-z0-9-', '')
          anchor = "#{path}-#{text}"
          "<dt class=\"hdlist1\" id=\"#{anchor}\"> <a class=\"anchor\" href=\"##{anchor}\"></a>#{$1} </dt>"
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
  Rails.cache.write("latest-version", Version.latest_version.name)
end
