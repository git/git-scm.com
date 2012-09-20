class BlogController < ApplicationController

  # for progit.org blog
  def progit
    year  = params[:year]
    month = params[:month]
    day   = params[:day]
    slug  = params[:slug]
    file  = [year, month, day, slug] * "-"
    blog = BlogPresenter.new(file)
    if blog.exists?
      @content, @frontmatter = blog.render
    else
      raise PageNotFound
    end
    render :progit
  end

  # for Gitscm blog
  def gitscm

  end

  private

 
end
