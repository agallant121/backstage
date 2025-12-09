Rails.application.routes.draw do
  devise_for :users

  resources :posts
  
  resources :groups do
    resources :memberships, only: [:create]
  end

  root "home#index"
end
