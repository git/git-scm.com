class DocController < ApplicationController
  layout "sidebar"

  def index
    p Gitscm::CATEGORIES
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
