Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "/health", to: "health#show"

  mount ActionCable.server => '/cable'

  namespace :api do
    namespace :v1 do
      resources :rides, only: [] do
        resources :locations, only: [:create], controller: 'ride_locations'
        resources :emergency_events, only: [:create]
        resources :riders, only: [:index]
        get :stats, on: :member, action: :show, controller: 'ride_stats'
      end
    end
  end
end
