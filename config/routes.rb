Rails.application.routes.draw do
  get "settings/index"
  get "settings/update"
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ActionCable
  mount ActionCable.server => '/cable'

  # Root path
  root "pages#home"
  
  # Custom dashboard route
  get "/dashboard", to: "pages#dashboard"
  
  # OAuth start routes
  get "/auth/youtube", to: "subscriptions#youtube_callback"
  
  # OAuth callbacks
  get "/auth/tiktok/callback", to: "subscriptions#tiktok_callback"
  get "/auth/youtube/callback", to: "subscriptions#youtube_callback"
  
  # Generic OAuth callback that determines platform
  get "/auth/:platform/callback", to: "subscriptions#create"
  
  # Subscription resources
  resources :subscriptions, only: [:index, :new, :create, :destroy]
  
  # Videos resources
  resources :videos, only: [:index, :show]
  
  # Analytics routes
  get "/analytics/demographics", to: "analytics#demographics", as: :analytics_demographics
  get "/analytics/comparison", to: "analytics#comparison"
  
  # Settings routes
  get "/settings", to: "settings#index"
  patch "/settings/update_realtime", to: "settings#update_realtime"
  
  # API endpoints for AJAX updates
  namespace :api do
    namespace :v1 do
      resources :analytics, only: [:index]
      resources :videos, only: [:index, :show]
    end
  end
  
  # Sidekiq web UI (protected by admin authentication)
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
