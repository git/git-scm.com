class DocController < ApplicationController
  layout "layout"

  def index
    @docs = DocFile.all
  end

  def ref
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
      @doc = doc_version.doc
    end
  end

  def book
  end

  def videos
  end

  def ext
  end

end
