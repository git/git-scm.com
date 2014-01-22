class BooksController < ApplicationController

  before_filter :book_resource, only: [:section, :chapter]
  before_filter :redirect_book, only: [:show]

  def show
    @book = Book.includes(:sections).where(:code => (params[:lang] || "en")).first
    raise PageNotFound unless @book
  end

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

  def section
    @content = @book.sections.where(:slug => params[:slug]).first
    return redirect_to "/book/#{@book.code}" unless @content
    @related = @content.get_related(8)
    if @content.title.blank?
      @page_title = "Git - #{@content.chapter.title}"
    else
      @page_title = "Git - #{@content.title}"
    end
  end

  def chapter
    chapter = params[:chapter].to_i
    section = params[:section].to_i
    chapter = @book.chapters.where(:number => chapter).first
    @content = chapter.sections.where(:number => section).first
    raise PageNotFound unless @content
    @page_title = "Git - #{@content.title}"
    render 'section'
  end

  private

  def redirect_book
    uri_path = params[:lang]
    if slug = REDIRECT[uri_path]
      return redirect_to lang_book_path(lang: slug)
    end
  end

  def book_resource
    @book ||= Book.where(:code => (params[:lang] || "en")).first
    raise PageNotFound unless @book
    @book
  end

end
