Gitscm::Application.routes.draw do
  get "site/index"

  root :to => 'site#index'
end
