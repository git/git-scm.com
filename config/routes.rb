# frozen_string_literal: true

Gitscm::Application.routes.draw do
  constraints(host: 'whygitisbetterthanx.com') do
    root to: 'site#redirect_wgibtx', as: :whygitisbetterthanx
  end

  constraints(host: 'progit.org') do
    root to: 'site#redirect_book', as: :progit
    get '*path' => 'site#redirect_book'
  end

  get 'site/index'

  scope :manual, as: :manual do
    get '/'    => 'doc#index'
    get '/ext' => 'doc#ext'
  end

  scope :manuals do
    get '/' => 'doc#ref'

    get '/howto/:file', to: redirect { |path_params, _req|
      "https://github.com/git/git/blob/master/Documentation/howto/#{path_params[:file]}.txt"
    }

    get '/:file.html' => 'doc#man', :as => :doc_file_html, :file => /[\w\-\.]+/
    get '/:file'      => 'doc#man', :as => :doc_file,      :file => /[\w\-\.]+/

    get '/:file/:version' => 'doc#man', :version => %r{[^\/]+}
  end

  scope :doc, as: :doc do
    get '/'    => redirect('/manual')
    get '/ext' => redirect('/manual/ext')
  end

  scope :docs do
    get '/' => redirect('/manuals')

    get '/howto/:file', to: redirect { |path_params, _req|
      "https://github.com/git/git/blob/master/Documentation/howto/#{path_params[:file]}.txt"
    }

    get '/:file.html' => redirect('/manuals/%<file>s.html'), :file => /[\w\-\.]+/
    get '/:file'      => redirect('/manuals/%<file>s'),      :file => /[\w\-\.]+/

    get '/:file/:version' => redirect('/manuals/%<file>s/%<version>s'), :version => %r{[^\/]+}
  end

  %w[man ref git].each do |path|
    get "/#{path}/:file" => redirect('/docs/%<file>s')
    get "/#{path}/:file/:version" => redirect('/docs/%<file>s/%<version>s'), :version => %r{[^\/]+}
  end

  resource :book do
    get '/ch:chapter-:section.html'       => 'books#chapter'
    get '/:lang/ch:chapter-:section.html' => 'books#chapter'

    get '/index'    => redirect('/book')
    get '/commands' => redirect('/docs')

    nested do
      scope ':lang' do
        get '/v:edition'                => 'books#show'
        get '/v:edition/:slug'          => 'books#section'
        get '/v:edition/:chapter/:link' => 'books#link', chapter: /(ch|app)\d+/

        get '/'      => 'books#show',    as: :lang
        get '/:slug' => 'books#section', as: :slug
      end
    end
  end

  scope :download, as: :download do
    get '/'              => 'downloads#index'
    get '/:platform'     => 'downloads#download'
    get '/gui/:platform' => 'downloads#gui'
  end

  resources :downloads, only: [:index] do
    collection do
      get '/guis'       => 'downloads#guis'
      get '/installers' => 'downloads#installers'
      get '/logos'      => 'downloads#logos'
      get '/latest'     => 'downloads#latest'
    end
  end

  get '/blog' => 'blog#index'
  get '/blog/*post' => redirect('/blog')
  get '/:year/:month/:day/:slug' => redirect('/blog'), :year => /\d{4}/, :month => /\d{2}/, :day => /\d{2}/

  get '/about'          => 'about#index'
  get '/about/:section' => 'about#index'

  get '/videos'    => 'doc#videos'
  get '/video/:id' => 'doc#watch'

  get '/community' => 'community#index'

  get '/search'         => 'site#search'
  get '/search/results' => 'site#search_results'

  # historical synonyms
  namespace :documentation do
    get '/'                     => redirect('/doc')
    get '/reference'            => redirect('/docs')
    get '/reference/:file.html' => redirect { |path_params, _req| "/docs/#{path_params[:file]}" }
    get '/book'                 => redirect('/book')
    get '/videos'               => redirect('/videos')
    get '/external-links'       => redirect('doc/ext')
  end

  get '/course/svn' => 'site#svn'
  get '/sfc'        => 'site#sfc'
  get '/trademark'  => redirect('/about/trademark')

  get '/contributors' => redirect('https://github.com/git/git/graphs/contributors')

  root to: 'site#index'
end
