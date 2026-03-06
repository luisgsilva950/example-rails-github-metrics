Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "metrics/dashboard#index"

  # Ranking de autores por número de commits + breakdown por repositório
  namespace :metrics do
    get "dashboard", to: "dashboard#index"
    get "authors", to: "authors#index"
    get "jira_bugs/unclassified", to: "jira_bugs#unclassified"
    get "jira_bugs/by_category", to: "jira_bugs#by_category"
    get "jira_bugs/invalid_categories", to: "jira_bugs#invalid_categories"
    get "jira_bugs/bubble_chart", to: "jira_bugs#bubble_chart"
    get "jira_bugs/bubble_chart_page", to: "jira_bugs#bubble_chart_page"
    get "jira_bugs/invalid_categories_page", to: "jira_bugs#invalid_categories_page"
    get "jira_bugs/all", to: "jira_bugs#all_bugs_page"
    get "jira_bugs/bugs_over_time", to: "jira_bugs#bugs_over_time_page", as: "jira_bugs_over_time"
    post "jira_bugs/sync_from_jira", to: "jira_bugs#sync_from_jira"
    get "support_tickets", to: "support_tickets#index"
    post "support_tickets/clone_to_bugs", to: "support_tickets#clone_to_bugs"
    post "sync_settings/toggle", to: "sync_settings#toggle"
  end

  namespace :admin do
    root to: "dashboard#index"
    get "analytics", to: "analytics#index"
    get "records/:model", to: "records#index", as: :records
    get "records/:model/:id", to: "records#show", as: :record
  end

  namespace :planning do
    resources :teams, only: %i[index new create edit update]
    resources :cycles, only: %i[index new create edit update] do
      member do
        get :plan
        get :burndown
      end
      resources :cycle_capacities, only: %i[create destroy] do
        collection do
          post :add_all
        end
      end
      resources :cycle_allocations, only: %i[create update destroy]
      resources :cycle_operational_activities, only: %i[create destroy]
      resources :burndown_entries, only: %i[create update destroy]
    end
    resources :deliverables, only: %i[index new create edit update]
    resources :developers, only: %i[index new create show edit update] do
      resources :absences, only: %i[create destroy]
    end
  end
end
