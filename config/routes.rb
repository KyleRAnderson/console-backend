Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :create, :show, :destroy] do
        resources :rosters, only: [:index, :create, :show, :destroy]
      end
    end
  end
  root 'homepage#index'
  get '/*path' => 'homepage#index' # Redirect non-api traffic to the client side.
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
