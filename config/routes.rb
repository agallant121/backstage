Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]
  devise_scope :user do
    invite_constraint = lambda do |request|
      request.params[:invite_token].present? || request.session[:invitation_token].present?
    end

    get "users/edit", to: "users/registrations#edit", as: :edit_user_registration
    patch "users", to: "users/registrations#update"
    put "users", to: "users/registrations#update"

    get "users/sign_up",
        to: "users/registrations#new",
        as: :new_user_registration,
        constraints: invite_constraint
    post "users",
         to: "users/registrations#create",
         as: :user_registration,
         constraints: invite_constraint
  end

  resources :posts
  resources :users, only: [ :show ], constraints: { id: /\d+/ }

  resources :groups do
    resources :memberships, only: [ :create, :destroy ]
    resources :invitations, only: [ :index, :create ], module: :groups do
      post :reissue, on: :member
    end
    get :members, on: :member
  end

  resources :invitations, only: [ :show ], param: :token do
    post :accept, on: :member
  end

  get "directory", to: "directory#index"

  root "home#index"
end
