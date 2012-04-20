
class DocController < ApplicationController
  layout "layout"

  def index
    @book = Book.where(:code => 'en').first
  end

  def ref
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

    # TODO: find and index commands
    render :text => 'ok'
  end

  # API Methods to update book content #

  def videos
  end

  def ext
  end

end
