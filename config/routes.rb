Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Stripe webhook
  post "/webhooks/stripe", to: "webhooks#stripe"

  # Secure downloads
  get "/downloads/:token", to: "downloads#show", as: :secure_download

  # Checkout
  resource :checkout, only: [:create], controller: "checkout"
  get "checkout/success", to: "checkout#success", as: :checkout_success
  get "checkout/cancel", to: "checkout#cancel", as: :checkout_cancel

  # Cart
  resource :cart, only: [:show] do
    collection do
      post :add
      delete :remove
      delete :clear
    end
  end

  # Catalog
  resources :ebooks, only: [:index, :show]
  resources :categories, only: [:show], param: :slug

  # Dashboard
  get "dashboard", to: "dashboard#show", as: :dashboard
  get "dashboard/library", to: "dashboard#library", as: :dashboard_library
  get "dashboard/orders", to: "dashboard#orders", as: :dashboard_orders

  # Static pages
  get "about", to: "pages#about"
  get "contact", to: "pages#contact"

  # Admin
  namespace :admin do
    get "/", to: "dashboard#show", as: :dashboard
    resources :ebooks
    resources :categories
    resources :orders, only: [:index, :show, :update]
    resources :users, only: [:index, :show]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "home#index"
end
