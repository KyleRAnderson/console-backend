# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, path: '', path_prefix: 'api/v1/', defaults: { format: 'json' },
                     path_names: { sign_in: 'login', sign_out: 'logout', registration: 'signup' },
                     controllers: { sessions: 'api/v1/sessions', registrations: 'api/v1/registrations',
                                    passwords: 'api/v1/passwords', confirmations: 'api/v1/confirmations' }
  namespace :api do
    namespace :v1 do
      shallow do
        resources :rosters, only: %i[index show create update destroy], defaults: { format: 'json' } do
          resources :permissions, only: %i[index show create update destroy], defaults: { format: 'json' }
          resources :participants, only: %i[index show create update destroy], defaults: { format: 'json' } do
            post 'upload', action: :upload, on: :collection
          end
          resources :hunts, only: %i[index show create update destroy], defaults: { format: 'json' } do
            resource :template_pdf, only: %i[create destroy], shallow: false, module: 'hunts'
            namespace :licenses do
              resources :instant_prints, path: 'print', only: %i[create], shallow: false
            end
            resources :licenses, only: %i[index show create update destroy], defaults: { format: 'json' } do
              collection do
                post 'bulk', controller: 'licenses/bulk', action: :create
                patch 'eliminate_all', action: :eliminate_all
                patch 'eliminate_half', action: :eliminate_half
              end
            end
            resources :rounds, only: %i[index show create destroy], defaults: { format: 'json' }, param: :number, shallow: false
            resources :matches, only: %i[index show create], defaults: { format: 'json' }, param: :number, shallow: false do
              post 'matchmake', action: :matchmake, on: :collection
            end
            namespace :matches do
              resource 'edits', only: :create, path: 'edit'
            end
          end
        end
      end
    end
  end
  root 'homepage#index'
  get '/confirmation/:confirmation_token', to: 'homepage#index', as: :frontend_user_confirmation
  get '/reset_password/:confirmation_token', to: 'homepage#index', as: :frontend_user_password_reset
  get '/*path', to: 'homepage#index', constraints: ->(req) do # Redirect non-api traffic to the client side.
                  req.path.exclude? 'rails/active_storage' # Ugly solution derived from https://github.com/rails/rails/issues/31228#issuecomment-352900551.
                end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
