Rails.application.routes.draw do
  devise_for :users

  resources :posts
  resources :users, only: [ :show ]

  resources :groups do
    resources :memberships, only: [ :create ]
  end

  get "directory", to: "directory#index"

  root "home#index"
end
