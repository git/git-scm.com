class DocController < ApplicationController
  layout "layout"

  def index
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
  end

  def book_section
  end

  def book_update
    # TODO: check credentials
    lang    = params[:lang]
    section = params[:section]
    content = params[:content]
  end

  # API Methods to update book content #

  def videos
  end

  def ext
  end

end
