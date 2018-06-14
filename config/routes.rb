Rails.application.routes.draw do
  root 'users#index'

  devise_for :users

  resources :users, only: [:index, :show]

  resources :games, only: [:create, :show] do
    put 'answer', on: :member
    put 'take_money', on: :member
  end
end
