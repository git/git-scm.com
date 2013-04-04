module BlogHelper
  def list_posts
    path = "#{Rails.root}/app/views/blog/posts/*.*"
    posts = []
    Dir[path].each do |uri|
      file = uri.match(/^.*\/(.{10})(.*).(markdown|html)/)
      posts << {:uri => file[0],
                  :file => file[1] + file[2],
                  :date_published => Date.parse(file[1]),
                  :title=> file[2].titleize,
                  :slug => file[2].parameterize
                }
    end
    posts = posts.sort_by { |k| k[:date_published] }.reverse
  end

  def format_path(post)
    "/blog/#{post[:date_published].year}/#{post[:date_published].strftime('%m')}/#{post[:date_published].strftime('%d')}/#{post[:slug]}.html"
  end

  def preview_post(postURI)
    post = BlogPresenter.new(postURI)
    post.render
  end
end
