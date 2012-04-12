Gitscm::Application.routes.draw do
  get "site/index"

  match "/doc" => "doc#index"
  match "/ref" => "doc#ref"
  match "/ref/:file" => "doc#man"
  match "/ref/:file/:version" => "doc#man", :version => /[^\/]+/
  match "/book" => "doc#book"
  match "/videos" => "doc#videos"
  match "/doc/ext" => "doc#ext"

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
