require 'asciidoctor'
require 'octokit'
require 'time'
require 'digest/sha1'

# fill in the db from a local git clone
task :preindex => :environment do
  ActiveRecord::Base.logger.level = Logger::WARN

  @octokit = Octokit::Client.new(:login => ENV['API_USER'], :password => ENV['API_PASS'])

  template_dir = File.join(Rails.root, 'templates')
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

    doc_files.each do |entry|
      path = File.basename( entry.path, '.txt' )
      file = DocFile.where(:name => path).first_or_create

      puts "   build: #{path}"

      content = blob_content[entry.sha]
      content.gsub!(/include::(\S+)\.txt/) do |line|
        line.gsub!("include::","")
        category_file = tag_files.detect { |ent| ent.path == "Documentation/#{line}" }
        if category_file
          blob_content[category_file.sha]
        end
      end
      asciidoc = Asciidoctor::Document.new(content, template_dir: template_dir)
      asciidoc_sha = Digest::SHA1.hexdigest( asciidoc.source )
      doc = Doc.where( :blob_sha => asciidoc_sha ).first_or_create
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
  Rails.cache.write("latest-version", Version.latest_version.name)
end

