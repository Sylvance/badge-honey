Rails.application.routes.draw do
  get 'logout', to: 'sessions#destroy', as: 'logout'
  get 'login', to: 'sessions#new', as: 'login'
  get 'signup', to: 'users#new', as: 'signup'
  root to: 'users#index'
  resources :users
  
resources :sessions, only: [:new, :create, :destroy]
# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
