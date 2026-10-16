Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]
  resources :passwords, param: :token

  resources :properties do
    resources :rooms, except: %i[ index show ]
  end

  resources :tenants, except: %i[ show destroy ] do
    member do
      patch :move_out
    end
  end

  # Health check untuk load balancer dan uptime monitor.
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
