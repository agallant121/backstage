Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  resources :posts
  resources :users, only: [ :show ]

  resources :groups do
    resources :memberships, only: [ :create ]
    resources :invitations, only: [ :index, :create ], module: :groups
  end

  resources :invitations, only: [ :show ], param: :token

  get "directory", to: "directory#index"

  root "home#index"
end
