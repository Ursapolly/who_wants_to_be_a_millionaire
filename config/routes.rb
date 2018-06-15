Rails.application.routes.draw do
  root 'users#index'

  devise_for :users

  resources :users, only: %i[index show]

  resources :games, only: %i[create show] do
    put 'help', on: :member
    put 'answer', on: :member
    put 'take_money', on: :member
  end

  resource :questions, only: %i[new create]
end
