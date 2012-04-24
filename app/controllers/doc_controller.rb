require 'redcarpet'

class DocController < ApplicationController
  layout "layout"

  def index
    @book = Book.where(:code => 'en').first
  end

  def ref
  end

  def blog
    y = params[:year]
    m = params[:month]
    d = params[:day]
    slug = params[:slug]
    file = "#{y}-#{m}-#{d}-#{slug}"
    @path = path = "#{Rails.root}/app/views/blog/progit/#{file}"
    content = ''
    if File.exists?("#{path}.markdown")
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      content = File.read("#{path}.markdown")
      content, @frontmatter = extract_frontmatter(content)
      @content = markdown.render(content)
    elsif File.exists?("#{path}.html")
      content = File.read("#{path}.html")
      @content, @frontmatter = extract_frontmatter(content)
    end
  end

  def extract_frontmatter(content)
    if content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)(.*)/m
      cnt = $3
      data = YAML.load($1)
      [cnt, data]
    else
      [content, {}]
    end
  end

  def test
    render 'doc/rebase'
  end

  def man
    if params[:version]
      doc_version = DocVersion.for_version(params[:file], params[:version])
    else
      doc_version = DocVersion.latest_for(params[:file])
    end

    if doc_version.nil?
      redirect_to :ref
    else
      @versions = DocVersion.version_changes(params[:file], 20)
      @last = DocVersion.last_changed(params[:file])
      @related = DocVersion.get_related(params[:file], 8)
      @version = doc_version.version
      @file = doc_version.doc_file
      @doc = doc_version.doc
    end
  end

  def book
    lang = params[:lang] || 'en'
    @book = Book.where(:code => lang).first
  end

  def book_section
    lang = params[:lang]
    slug = params[:slug]
    @content = Book.where(:code => lang).first.sections.where(:slug => slug).first
    @related = @content.get_related(8)
  end

  CMD_GROUPS = [
       ['Setup and Config', [ 'config', 'help' ]],
       ['Getting and Creating Projects', [ 'init', 'clone']],
       ['Basic Snapshotting', [ 'add', 'status', 'diff', 'commit', 'reset', 'rm', 'mv']],
       ['Branching and Merging', [ 'branch', 'checkout', 'merge', 'mergetool', 'log', 'stash', 'tag' ]],
       ['Sharing and Updating Projects', [ 'fetch', 'pull', 'push', 'remote', 'submodule' ]],
       ['Inspection and Comparison', [ 'show', 'log', 'diff', 'shortlog', 'describe' ]],
       ['Patching', ['am', 'apply', 'cherry-pick', 'rebase']],
       ['Debugging', [ 'bisect', 'blame' ]],
       ['Email', ['am', 'apply', 'format-patch', 'send-email', 'request-pull']],
       ['External Sytems', ['svn', 'fast-import']],
       ['Administration', [ 'gc', 'fsck', 'reflog', 'filter-branch', 'instaweb', 'archive' ]],
       ['Server Admin', [ 'daemon', 'update-server-info' ]],
  ]

  # commands index
  def commands
    @related = {}
    ri = RelatedItem.where(:content_type => 'reference', :related_type => 'book')
    ri.each do |item|
      cmd = item.name.gsub('git-', '')
      if s = Section.where(:slug => item.related_id).first
        @related[cmd] ||= []
        @related[cmd] << [s.cs_number, s.slug, item.score]
        @related[cmd].sort!
      end
    end
    @groups = CMD_GROUPS
  end

  def related_update
    if params[:token] != ENV['UPDATE_TOKEN']
      return render :text => 'nope'
    end

    from = params[:from_content]
    to = params[:to_content]
    RelatedItem.create_both(from, to)
    render :text => 'ok'
  end

  # so we can display urls old progit.org style
  def progit
    chapter = params[:chapter].to_i
    section = params[:section].to_i
    lang = params[:lang] || 'en'
    book = Book.where(:code => lang).first
    chapter = book.chapters.where(:number => chapter).first
    @content = chapter.sections.where(:number => section).first
    render 'book_section'
  end

  # API Methods to update book content #

  def book_update
    if params[:token] != ENV['UPDATE_TOKEN']
      return render :text => 'nope'
    end

    lang    = params[:lang]
    chapter = params[:chapter].to_i
    section = params[:section].to_i
    chapter_title = params[:chapter_title]
    section_title = params[:section_title]
    content = params[:content].force_encoding("UTF-8")

    # create book (if needed)
    book = Book.where(:code => lang).first_or_create

    # create chapter (if needed)
    chapter = book.chapters.where(:number => chapter).first_or_create
    chapter.title = chapter_title
    chapter.save

    # create/update section
    section = chapter.sections.where(:number => section).first_or_create
    section.title = section_title
    section.html = content
    section.save

    render :text => 'ok'
  end

  def videos
  end

  def ext
  end

end
