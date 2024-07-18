# frozen_string_literal: true

require 'resque/server'

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  devise_scope :user do
    get '/users/development/sign_in_developer', to: 'users/development#sign_in_developer' if Rails.env.development?
  end

  resque_web_constraint = lambda do |request|
    current_user = request.env['warden'].user
    current_user.present?
  end

  constraints resque_web_constraint do
    mount Resque::Server.new, at: '/resque'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'pages#home'

  post '/fixity_checks/run_fixity_check_for_s3_object', to: 'fixity_checks#run_fixity_check_for_s3_object'

  # Mount ActionCable Websocket route
  mount ActionCable.server => '/cable'
end
