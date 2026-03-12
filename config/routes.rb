Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Catalog
  resources :ebooks, only: [:index, :show]
  resources :categories, only: [:show], param: :slug

  # User library features
  resources :favorites, only: [:create, :destroy]
  resources :reading_list_items, only: [:create, :update, :destroy]
  get "profile", to: "profiles#show", as: :profile

  # Static pages
  get "about", to: "pages#about"
  get "contact", to: "pages#contact"

  # Admin
  namespace :admin do
    get "/", to: "dashboard#show", as: :dashboard
    resources :ebooks
    resources :categories
    resources :users, only: [:index, :show]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "home#index"
end
