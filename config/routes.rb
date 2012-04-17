Gitscm::Application.routes.draw do
  get "site/index"

  match "/doc" => "doc#index"
  match "/ref" => "doc#ref"
  match "/ref/:file" => "doc#man"
  match "/ref/:file/:version" => "doc#man", :version => /[^\/]+/
  match "/test" => "doc#test"
  match "/videos" => "doc#videos"
  match "/doc/ext" => "doc#ext"

  match "/book" => "doc#book"
  match "/book/:lang" => "doc#book"
  match "/book/:lang/:slug" => "doc#book_section"
  match "/book/update" => "doc#book_update"

  match "/about" => "about#index"
  match "/community" => "community#index"

  match "/admin" => "site#admin"

  match "/downloads" => "downloads#index"
  match "/downloads/guis" => "downloads#guis"
  match "/downloads/installers" => "downloads#installers"
  match "/downloads/logos" => "downloads#logos"
  match "/download/:platform" => "downloads#download"
  match "/download/gui/:platform" => "downloads#gui"

  match "/search" => "site#search"

  # mapping for jasons mocks
  match "/documentation" => "doc#index"
  match "/documentation/reference" => "doc#ref"
  match "/documentation/reference/:file.html" => "doc#man"
  match "/documentation/book" => "doc#book"
  match "/documentation/videos" => "doc#videos"
  match "/documentation/external-links" => "doc#ext"

  # TODO: old routes to new pages

  root :to => 'site#index'
end
