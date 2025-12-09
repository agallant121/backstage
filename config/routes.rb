Rails.application.routes.draw do
  devise_for :users

  resources :posts
  resources :groups

  root "home#index"
end
