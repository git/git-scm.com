Gitscm::Application.routes.draw do

  constraints(:host => 'whygitisbetterthanx.com') do
    root :to => 'site#redirect_wgibtx', as: :whygitisbetterthanx
  end

  constraints(:host => 'progit.org') do
    root :to => 'site#redirect_book', as: :progit
    get '*path' => 'site#redirect_book'
  end

#  constraints(:subdomain => 'book') do
#    root :to => 'site#redirect_book'
#    get '*path' => 'site#redirect_combook'
#  end

  constraints(:host => 'libgit2.github.com') do
    root :to => 'library#index'
  end

  get "site/index"

  get "/doc" => "doc#index"
  get "/docs" => "doc#ref"
  get "/docs/howto/:file", to: redirect {|path_params, req|
    "https://github.com/git/git/blob/master/Documentation/howto/#{path_params[:file]}.txt"
  }
  get "/docs/:file.html" => "doc#man", :as => :doc_file_html, :file => /[\w\-\.]+/
  get "/docs/:file" => "doc#man", :as => :doc_file, :file => /[\w\-\.]+/
  get "/docs/:file/:version" => "doc#man", :version => /[^\/]+/
  get "/test" => "doc#test"
  get "/doc/ext" => "doc#ext"

  %w{man ref git}.each do |path|
    get "/#{path}/:file" => redirect("/docs/%{file}")
    get "/#{path}/:file/:version" => redirect("/docs/%{file}/%{version}"),
    :version => /[^\/]+/
  end

  resource :book do
    get "/ch:chapter-:section.html"    => "books#chapter"
    get "/:lang/ch:chapter-:section.html" => "books#chapter"
    get "/index"                          => redirect("/book")
    get "/commands"                       => "books#commands"
    get "/:lang/v:edition"                => "books#show"
    get "/:lang/v:edition/:slug"          => "books#section"
    get "/:lang/v:edition/:chapter/:link" => "books#link", chapter: /(ch|app)\d+/
    get "/:lang"                          => "books#show", as: :lang
    get "/:lang/:slug"                    => "books#section"
  end
  post "/update"   => "books#update"

  get "/download"               => "downloads#index"
  get "/download/:platform"     => "downloads#download"
  get "/download/gui/:platform" => "downloads#gui"

<<<<<<< HEAD
=======
  match "/download"               => "downloads#index"
  match "/download/:platform"     => "downloads#download"
  match "/download/gui/:platform" => "downloads#gui"

>>>>>>> refs/remotes/origin/library
  resources :downloads, :only => [:index] do
    collection do
      get "/guis"       => "downloads#guis"
      get "/installers" => "downloads#installers"
      get "/logos"       => "downloads#logos"
      get "/latest"     => "downloads#latest"
    end
  end

  get "/:year/:month/:day/:slug" => "blog#post",  :year   => /\d{4}/,
                                                    :month  => /\d{2}/,
                                                    :day    => /\d{2}/

  get "/blog/:year/:month/:day/:slug" => "blog#post",  :year   => /\d{4}/,
                                                    :month  => /\d{2}/,
                                                    :day    => /\d{2}/

  get "/blog.rss" => "blog#feed"
  get "/blog" => "blog#index"

  get "/publish"  => "doc#book_update"
  post "/related" => "doc#related_update"

  get "/about" => "about#index"
  get "/about/:section" => "about#index"

  get "/videos" => "doc#videos"
  get "/video/:id" => "doc#watch"

  get "/community" => "community#index"

  get "/admin" => "site#admin"

  get "/search" => "site#search"
  get "/search/results" => "site#search_results"

  # mapping for jasons mocks
<<<<<<< HEAD
  get "/documentation" => "doc#index"
  get "/documentation/reference" => "doc#ref"
  get "/documentation/reference/:file.html" => "doc#man"
  get "/documentation/book" => "doc#book"
  get "/documentation/videos" => "doc#videos"
  get "/documentation/external-links" => "doc#ext"

  get "/course/svn" => "site#svn"
  get "/sfc" => "site#sfc"
  get "/trademark" => "site#trademark"

  get "/contributors" => redirect("https://github.com/git/git/graphs/contributors")
=======
  match "/documentation" => "doc#index"
  match "/documentation/reference" => "doc#ref"
  match "/documentation/reference/:file.html" => "doc#man"
  match "/documentation/book" => "doc#book"
  match "/documentation/videos" => "doc#videos"
  match "/documentation/external-links" => "doc#ext"

  get "/library" => "library#index"
  get "/library/api/(:version)" => "library#api", :version => /(HEAD|v\d+\.\d+\.\d+)/, :defaults => {:version => 'HEAD'} 
  get "/library/api/:version/f/:fname" => "library#function", :version => /(HEAD|v\d+\.\d+\.\d+)/
  get "/library/api/:version/g/:gname" => "library#group", :version => /(HEAD|v\d+\.\d+\.\d+)/

  match "/course/svn" => "site#svn"
  match "/sfc" => "site#sfc"
>>>>>>> refs/remotes/origin/library

  root :to => 'site#index'
end
