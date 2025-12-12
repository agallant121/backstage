Rails.application.routes.draw do
  devise_for :users

  resources :posts
  resources :users, only: [ :show ]

  resources :groups do
    resources :memberships, only: [ :create ]
  end

  root "home#index"
end
