require 'sidekiq/web'

Reckoning::Application.routes.draw do
  scope module: "api", constraints: { subdomain: "api" } do
    namespace :v1 do
      post 'signin' => 'session#create'
      resource :account
      resources :customers, only: [:index, :show, :create, :destroy]
      resources :projects, only: [:index, :destroy] do
        member do
          put :archive
        end
      end
      resources :tasks, only: [:index, :create]
      resources :timers, only: [:index, :create, :update, :destroy] do
        member do
          put :start
          put :stop
        end
      end
    end
  end

  namespace :backend do
    scope module: "api", constraints: { subdomain: "api" } do
      namespace :v1 do
        resources :accounts
      end
    end

    resources :accounts, except: [:show]

    resources :users, except: [:show] do
      member do
        put 'send_welcome'
      end
    end

    resources :settings, except: [:index, :show]

    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => '/workers'
    end

    root to: 'base#dashboard'
  end

  devise_for :users,
             skip: [:sessions, :registrations],
             controllers: { registrations: "registrations" }

  as :user do
    get 'signup' => 'accounts#new', as: :new_registration
    post 'signup' => 'accounts#create', as: :registration
    get 'settings' => 'registrations#edit', as: :edit_user_registration
    patch 'settings' => 'registrations#update', as: :update_user_registration
    get 'signin' => 'sessions#new', as: :new_user_session
    post 'signin' => 'sessions#create', as: :user_session
    delete 'signout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :account, only: [:edit, :update]

  resource :password, only: [:edit, :update]

  resources :invoices do
    collection do
      put "archive" => "invoices#archive_all"
    end
    member do
      put :generate_positions
      put :regenerate_pdf
      put :charge
      put :pay
      get :check_pdf
      put :archive
      put :send_mail
      post :send_test_mail
    end
  end

  get 'invoices/:id/pdf/:pdf' => 'invoices#pdf', as: :invoice_pdf

  resource :timesheet, only: [:show] do
    member do
      get :day_template
      get :week_template
      get :timer_modal_template
      get :task_modal_template
    end
    # get :new_import
    # post :csv_import
  end

  resource :template, only: [] do
    get :blank
    get :datepicker
  end

  get 'timesheets/:id/pdf/:pdf' => 'invoices#timesheet', as: :timesheet_pdf

  resources :positions, only: [:new, :destroy]

  resources :customers, only: [:edit, :update]
  resources :projects, except: [:destroy] do
    member do
      put :unarchive
    end

    resources :tasks, only: [:index, :create] do
      collection do
        get :uninvoiced
      end
    end
  end

  resources :weeks, only: [:create, :update] do
    collection do
      post :add_task
    end
    member do
      put 'remove_task/:task_id' => 'weeks#remove_task', as: :remove_task
    end
  end

  resource :dropbox, controller: "dropbox", only: [:show] do
    collection do
      get :start
      get :activate
      get :deactivate
    end
  end

  get '404' => 'errors#not_found'
  get '422' => 'errors#server_error'
  get '500' => 'errors#server_error'

  get 'two_factor_qrcode' => 'two_factor#qrcode', constraints: { format: :png }

  root to: 'base#index'
end
