Rails.application.routes.draw do
  resources :draft_versions
  resources :comments
  require "sidekiq/web"
  devise_for :users, defaults: { format: :json }, path: "", path_names: {
                       sign_in: "login",
                       registration: "signup",
                     }, controllers: {
                       sessions: "users/sessions",
                       registrations: "users/registrations",
                       passwords: 'users/passwords'
                     }
  # Sessions
  devise_scope :user do
    delete "logout", to: "users/sessions#logout"
  end
  resources :categories
  resources :access_levels
  resources :permissions, only: [:index, :show]
  resources :roles, except: [:new, :edit] do
    member do
      post :update
      post :detach_permissions
      post "attach-permissions", to: "roles#add_permissions"
      delete "revoke-permissions", to: "roles#remove_permissions"
      post "attach-users", to: "roles#add_users"
      delete "revoke-users", to: "roles#remove_users"
    end
  end
  # passwords
  post '/forgot', to: 'passwords#forgot', default: { format: :json }
  post '/reset', to: 'passwords#reset', default: { format: :json }
  get '/password/edit', to: 'passwords#edit', default: { format: :json }

  scope module: :users do
    resources :users, only: [:index, :create, :destroy, :show, :update, :chat, :update_profile_image] do
      collection do
        get :current
        get :permissions
        post :assign_roles
        delete :detach_roles, as: :detach_roles
      end
      member do
        post :update, path: "update_details"
        post :chat, path: "chat"
        post :update_profile_image, path: "profile-image"
        get :notifications, path: "notifications"
      end
    end
  end
  # media files
  resources :media, only: [:index, :create, :destroy, :show, :update] do
    # collection do
    # end
    member do
      get :serve
      post :update, path: "update"
      get :download, path: "download"
    end
  end

  resources :drafts, only: [:index, :create, :update, :show, :destroy, :shared_drafts] do
    # Shared drafts
    collection do
      get :shared_drafts, path: "shared-drafts"
    end
    member do
      post "start_review"
      post "approve"
      post "reject"
      post "remove_collaborator"
      post "add_collaborator"
      post :update
      get :history, path: "history"
    end
  end

  # Define routes for OTP actions
  post "otp/send", to: "otp#send_otp"
  post "otp/resend", to: "otp#resend"
  post "otp/verify", to: "otp#verify"

  # Define routes for enabling and disabling OTP
  post "otp/enable", to: "otp#enable_two_factor"
  post "otp/disable", to: "otp#disable_two_factor"
  post "/users/:user_id/otp/enable", to: "otp#enable_two_factor_for_user"
  post "/users/:user_id/otp/disable", to: "otp#disable_two_factor_for_user"

  # notifications
  resources :notifications do
    post :mark_as_read, on: :member, path: "mark-as-read"
    post :mark_all_as_read, on: :collection, path: "mark-all-read"
  end
  # Conversations and chats
  resources :conversations, only: [:index, :create, :show, :destroy, :update] do
    member do
      post :archive
      post :unarchive
      post :share
      post :update
    end
    resources :chats, only: [:index, :create, :update] do
      member do
        patch :highlight
        post :like
        post :dislike
        post :update, path: "update"
      end
    end
  end

  resources :comments, only: [:index, :create, :destroy, :update, :show]

  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => "/cable"
  mount Sidekiq::Web => "/sidekiq"
end
