Gitscm::Application.routes.draw do
  get "site/index"

  match "/doc" => "doc#index"
  match "/doc/:file" => "doc#show"

  # TODO: old routes to new pages

  root :to => 'site#index'
end
