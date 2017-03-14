class BooksController < ApplicationController
  skip_before_filter  :verify_authenticity_token, only: [:update]

  before_filter :book_resource, only: [:section, :chapter]
  before_filter :redirect_book, only: [:show]

  def show
    lang = params[:lang] || "en"
    if edition = params[:edition]
      @book = Book.where(:code => lang, :edition => edition).first
    else
      @book = Book.where(:code => lang).order("percent_complete DESC, edition DESC").first
      raise PageNotFound unless @book
      redirect_to "/book/#{lang}/v#{@book.edition}"
    end
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

  def link
    link = params[:link]
    @book = Book.where(:code => params[:lang], :edition => params[:edition]).first
    raise PageNotFound unless @book
    xref = @book.xrefs.where(:name => link).first
    raise PageNotFound unless xref
    return redirect_to "/book/#{@book.code}/v#{@book.edition}/#{ERB::Util.url_encode(xref.section.slug)}##{xref.name}" unless @content
  end

  def section
    @content = @book.sections.where(:slug => params[:slug]).first
    if !@content
      @book = Book.where(:code => @book.code, :edition => 1).first
      if @content = @book.sections.where(:slug => params[:slug]).first
        return redirect_to "/book/#{@book.code}/v#{@book.edition}/#{params[:slug]}"
      else
        return redirect_to "/book/#{@book.code}"
      end
    elsif @no_edition
      return redirect_to "/book/#{@book.code}/v#{@book.edition}/#{params[:slug]}"
    end
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
    lang = params[:lang] || "en"
    chapter = @book.chapters.where(:number => chapter).first
    @content = chapter.sections.where(:number => section).first
    raise PageNotFound unless @content
    return redirect_to "/book/#{lang}/v2/#{@content.slug}"
  end

  def update
    if params[:token] == ENV['UPDATE_TOKEN']
      build = params[:build]
      if book = Book.where(:code => build[:code], :edition => build[:edition].to_i).first
        book.ebook_pdf  = build[:download][:pdf]
        book.ebook_epub = build[:download][:epub]
        book.ebook_mobi = build[:download][:mobi]
        book.ebook_html = build[:download][:html]
        book.processed  = false
        book.percent_complete = build[:percent].to_i
        book.save
      end
      render :text => 'OK'
    else
      render :text => 'NOPE - AUTH'
    end
  end

  private

  def redirect_book
    uri_path = params[:lang]
    if slug = REDIRECT[uri_path]
      /^(.*?)\/(.*)/.match(slug) do |m|
        return redirect_to slug_book_path(lang: m[1], slug: m[2])
      end
      return redirect_to lang_book_path(lang: slug)
    end
  end

  def book_resource
    if edition = params[:edition]
      @book ||= Book.where(:code => (params[:lang] || "en"), :edition => edition).first
    else
      @no_edition = true
      @book ||= Book.where(:code => (params[:lang] || "en")).order("percent_complete DESC, edition DESC").first
    end
    raise PageNotFound unless @book
    @book
  end

end
