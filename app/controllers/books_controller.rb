class BooksController < ApplicationController
  before_filter :book_resource, only: [:section, :chapter]

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
    if @content.title.blank?
      @page_title = "#{@content.chapter.title} · Git"
    else
      @page_title = "#{@content.title} · Git"
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

  def redirect_book
    uri_path = params[:lang]
    if (slug = REDIRECT[uri_path])
      /^(.*?)\/(.*)/.match(slug) do |m|
        return redirect_to book_slug_path(lang: m[1], slug: m[2])
      end
      return redirect_to book_lang_path(lang: slug)
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
