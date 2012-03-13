class DocController < ApplicationController
  layout "sidebar"

  def index
    p Gitscm::CATEGORIES
    @docs = DocFile.all
  end

  def show
  end
end
