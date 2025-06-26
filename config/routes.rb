Rails.application.routes.draw do
  get "settings/index"
  get "settings/update"
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
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
  
  # AJAX endpoints for dashboard performance optimization
  get "/dashboard/load_analytics_data", to: "pages#load_analytics_data"
  get "/dashboard/load_yearly_history", to: "pages#load_yearly_history"
  get "/dashboard/update_dashboard_data", to: "pages#update_dashboard_data"
  
  # Billing routes
  get "/pricing", to: "billing#pricing", as: :pricing
  get "/billing", to: "billing#index", as: :billing
  post "/billing/create_checkout_session", to: "billing#create_checkout_session", as: :create_checkout_session
  get "/billing/success", to: "billing#success", as: :billing_success
  get "/billing/cancel", to: "billing#cancel", as: :billing_cancel
  post "/billing/portal", to: "billing#portal", as: :billing_portal
  post "/billing/cancel_subscription", to: "billing#cancel_subscription", as: :cancel_subscription
  post "/billing/dev_bypass", to: "billing#dev_bypass", as: :dev_bypass
  
  # Subscription status acknowledgment
  post "/acknowledge_subscription_status", to: "pages#acknowledge_subscription_status"
  
  # Stripe webhooks
  post "/webhooks/stripe", to: "stripe_webhooks#create"
  
  # CSP violation reporting for production security monitoring
  post "/csp-violation-report-endpoint", to: "application#csp_violation_report"
  
  # OAuth start routes (redirect to provider)
  get "/auth/youtube", to: "subscriptions#youtube_oauth_start", as: :auth_youtube
  
  # OAuth callbacks (handle provider response)
  get "/auth/tiktok/callback", to: "subscriptions#tiktok_callback"
  get "/auth/youtube/callback", to: "subscriptions#youtube_callback", as: :auth_youtube_callback
  
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
  
  # Admin routes
  namespace :admin do
    resources :analytics, only: [:index]
  end
  
  # Sidekiq web UI (protected by admin authentication)
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Pages
  get 'privacy', to: 'pages#privacy'
  get 'terms', to: 'pages#terms'
  get 'posthog_test', to: 'pages#posthog_test'
  get 'button_test', to: 'pages#button_test'
end
