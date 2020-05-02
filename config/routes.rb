Rails.application.routes.draw do
  devise_for :users, path: "", path_prefix: "api/v1/", defaults: { format: "json" },
                     path_names: { sign_in: "login", sign_out: "logout", registration: "signup" },
                     controllers: { sessions: "api/v1/sessions", registrations: "api/v1/registrations", passwords: "api/v1/passwords", confirmations: "api/v1/confirmations" }
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :create, :show, :destroy], defaults: { format: "json" }
      resources :rosters, only: [:index, :create, :show, :destroy], defaults: { format: "json" }
    end
  end
  root "homepage#index"
  get "/*path" => "homepage#index" # Redirect non-api traffic to the client side.
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
