class DocController < ApplicationController

  before_filter :book_resource, :only => [:index]

  def index
    @videos = VIDEOS
  end

  def ref
  end

  def test
    render 'doc/rebase'
  end

  def man
    latest = Rails.cache.read("latest-version")
    filename = params[:file]
    version = params[:version] # || latest
    @cache_key = "man-v3-#{filename}-#{latest}-#{version}"

    if !Rails.cache.exist?("views/" + @cache_key)
      doc_version = doc_for filename, version
      if doc_version.nil?
        filename = "git-#{filename}"
        doc_version = doc_for filename, version
        redirect_to doc_file_url(filename) unless doc_version.nil?
      end

      if doc_version.nil?
        redirect_to '/docs'
      else
        key = "version-changes-#{doc_version.id}"
        @versions = Rails.cache.fetch(key) do
          DocVersion.version_changes(filename, 20)
        end
        @last = DocVersion.last_changed(filename)
        @related = DocVersion.get_related(filename, 8)
        @version = doc_version.version
        @file = doc_version.doc_file
        @page_title = "Git - #{@file.name} v#{@version.name} Documentation"
        @doc = doc_version.doc
      end
    end
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

  def book_resource
    @book ||= Book.where(:code => (params[:lang] || "en")).first
    raise PageNotFound unless @book
    @book
  end

  def doc_for(filename, version = nil)
    if version
      doc_version = DocVersion.for_version filename, version
    else
      doc_version = DocVersion.latest_for filename
    end
  end

end
