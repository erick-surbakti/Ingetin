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

  resources :invoices, only: %i[ index show ] do
    collection do
      post :generate
    end
    member do
      post :mark_sent
      patch :mark_paid
    end
    resources :items, controller: "invoice_items", only: %i[ create destroy ]
  end

  # Halaman tagihan untuk penghuni, dibuka dari link WhatsApp tanpa login.
  get "t/:token" => "public_invoices#show", as: :public_invoice
  post "t/:token/payments" => "public_payments#create", as: :public_invoice_payments

  resource :payment_settings, only: %i[ edit update ]

  # Notifikasi pembayaran dari Midtrans (HTTP notification / webhook).
  post "webhooks/midtrans" => "midtrans_webhooks#create", as: :midtrans_webhook

  # Health check untuk load balancer dan uptime monitor.
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
