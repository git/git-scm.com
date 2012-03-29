class DocController < ApplicationController
  layout "layout"

  def index
    @docs = DocFile.all
  end

  def ref
  end

  def man
  end

  def book
  end

  def videos
  end

  def ext
  end

end
