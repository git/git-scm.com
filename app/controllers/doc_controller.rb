class DocController < ApplicationController

  before_filter :set_caching
  before_filter :set_doc_file, only: [:man]
  before_filter :set_doc_version, only: [:man]
  before_filter :set_book, only: [:index]

  def index
    @videos = Gitscm::VIDEOS
  end

  def ref
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
  end

  def videos
    @videos = Gitscm::VIDEOS
  end

  def watch
    slug = params[:id]
    @video = Gitscm::VIDEOS.select{|a| a[4] == slug}.first
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
      @doc_file = DocFile.where(name: file).limit(1).first
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
