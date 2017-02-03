class DocController < ApplicationController

  before_filter :set_caching
  before_filter :set_doc_file, only: [:man]
  before_filter :set_doc_version, only: [:man]
  before_filter :set_book, only: [:index]

  def index
    @videos = VIDEOS
  end

  def ref
  end

  def test
    render 'doc/rebase'
  end

  def man
    return redirect_to docs_path unless @doc_file
    unless @doc_version.respond_to?(:version)
      return redirect_to doc_file_path(file: @doc_file.name)
    end
    @version  = @doc_version.version
    @doc      = @doc_version.doc
    @page_title = "Git - #{@doc_file.name} Documentation"
    return redirect_to docs_path unless @doc_version
    @last     = @doc_file.doc_versions.latest_version
    # @versions = DocVersion.version_changes(@doc_file.name)
    # @related = DocVersion.get_related(filename, 8)
  end

  def related_update
    if params[:token] != ENV['UPDATE_TOKEN']
      return render :text => 'nope'
    end

    fromc = params[:from_content]
    toc = params[:to_content]
    RelatedItem.create_both(fromc, toc)
    render :text => 'ok'
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
    @videos = VIDEOS
  end

  def watch
    slug = params[:id]
    @video = VIDEOS.select{|a| a[4] == slug}.first
    if !@video
      redirect_to :videos
    end
  end

  def ext
  end

  private

  def set_caching
    expires_in 10.minutes, :public => true
  end

  def set_book
    @book ||= Book.where(:code => (params[:lang] || "en")).order("percent_complete, edition DESC").first
    raise PageNotFound unless @book
  end

  def set_doc_file
    file  = params[:file]
    if DocFile.exists?(name: file)
      @doc_file = DocFile.with_includes.where(name: file).limit(1).first
    elsif DocFile.exists?(name: "git-#{file}")
      return redirect_to doc_file_path(file: "git-#{file}")
    end
  end

  def set_doc_version
    return unless @doc_file
    version = params[:version]
    if version
      @doc_version = @doc_file.doc_versions.for_version(version)
    else
      @doc_version = @doc_file.doc_versions.latest_version
    end
  end

end
