class BooksController < ApplicationController

  before_filter :book_resource, :only => [:section, :chapter]
  
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
    @page_title = "Git - #{@content.title}"
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

  def book_resource
    @book ||= Book.where(:code => (params[:lang] || "en")).first
    raise PageNotFound unless @book
    @book
  end

end
