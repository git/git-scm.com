# frozen_string_literal: true

class DocController < ApplicationController
  before_action :set_caching
  before_action :set_doc_file, only: [:man]
  before_action :set_doc_version, only: [:man]
  before_action :set_book, only: [:index]

  def index
    @videos = Gitscm::VIDEOS
  end

  def ref; end

  def man
    return redirect_to docs_path unless @doc_file
    unless @doc_version.respond_to?(:version)
      return redirect_to doc_file_path(file: @doc_file.name)
    end

    @version  = @doc_version.version
    @language = @doc_version.language
    @doc      = @doc_version.doc
    @name     = @doc_file.name
    @page_title = "Git - #{@doc_file.name} Documentation"
    return redirect_to docs_path unless @doc_version

    @last     = @doc_file.doc_versions.latest_version
  end

  def videos
    @videos = Gitscm::VIDEOS
  end

  def watch
    slug = params[:id]
    @video = Gitscm::VIDEOS.find { |a| a[4] == slug }
    if !@video
      redirect_to :videos
    end
  end

  def ext; end

  def credential_helpers; end

  private

  def set_caching
    expires_in 10.minutes, public: true
  end

  def set_book
    @book ||= Book.where(code: (params[:lang] || "en")).order("percent_complete, edition DESC").first
    raise PageNotFound unless @book
  end

  def set_doc_file
    file  = params[:file]
    if DocFile.exists?(name: file)
      @doc_file = DocFile.where(name: file).limit(1).first
    elsif DocFile.exists?(name: "git-#{file}")
      redirect_to doc_file_path(file: "git-#{file}")
    end
  end

  helper_method :revision?
  def revision?(name)
    /\d+(\.\d+)+/ =~ name
  end

  def set_doc_version
    return unless @doc_file

    version = params[:version]
    if version && revision?(version)
      @doc_version = @doc_file.doc_versions.for_version(version)
    else
      @doc_version = @doc_file.doc_versions.latest_version(version || "en")
    end
  end
end
