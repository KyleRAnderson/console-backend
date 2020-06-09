# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, path: '', path_prefix: 'api/v1/', defaults: { format: 'json' },
                     path_names: { sign_in: 'login', sign_out: 'logout', registration: 'signup' },
                     controllers: { sessions: 'api/v1/sessions', registrations: 'api/v1/registrations', passwords: 'api/v1/passwords', confirmations: 'api/v1/confirmations' }
  namespace :api do
    namespace :v1 do
      shallow do
        resources :users, only: %i[index create show destroy], defaults: { format: 'json' }
        resources :rosters, only: %i[index create show destroy], defaults: { format: 'json' } do
          resources :participants, only: %i[index create show destroy update], defaults: { format: 'json' }
          resources :hunts, only: %i[index create show destroy update], defaults: { format: 'json' } do
            resources :licenses, only: %i[index create show destroy update], defaults: { format: 'json' }
            resources :rounds, only: %i[index create show destroy], defaults: { format: 'json' }, param: :number, shallow: false
            resources :matches, only: %i[index create show destroy], defaults: { format: 'json' }, param: :number, shallow: false
            post '/matchmake/', to: 'matches#matchmake'
          end
        end
      end
    end
  end
  root 'homepage#index'
  get '/confirmation/:confirmation_token', to: 'homepage#index', as: :frontend_user_confirmation
  get '/*path' => 'homepage#index' # Redirect non-api traffic to the client side.
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
