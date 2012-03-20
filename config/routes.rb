Gitscm::Application.routes.draw do
  get "site/index"

  match "/doc" => "doc#index"
  match "/doc/ref" => "doc#ref"
  match "/doc/ref/:file" => "doc#man"
  match "/doc/book" => "doc#book"
  match "/doc/videos" => "doc#videos"
  match "/doc/ext" => "doc#ext"

  # TODO: old routes to new pages

  root :to => 'site#index'
end
