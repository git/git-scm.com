class DocController < ApplicationController
  layout "layout"

  def index
    @docs = DocFile.all
  end

  def ref
  end

  def man
    p params
    @docfile = DocFile.where(:name => params[:file]).first
    @doc = @docfile.doc_versions.first.doc.plain
    p @doc
  end

  def book
  end

  def videos
  end

  def ext
  end

end
