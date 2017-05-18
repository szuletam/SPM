# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get '/helps_aig', :to => redirect('ayudas/index.html'), :as => 'helps_aig'
resources :project_queries, :except => [:show]
match '/context_menu/projects/', :to => 'context_menus#projects', :as => 'projects_context_menu', :via => [:get, :post]
match '/get_done_ratio/get_done_ratio/:project_id', :to => 'issues#get_done_ratio', :as => 'issue_get_done_ratio', :via => [:post]
match '/issues/validate_recurrence', :to => 'issues#validate_recurrence', :action => 'validate_recurrence', :as => 'validate_recurrence', :via => [:get, :post]
match '/issues/validate_recurrence_for_committee', :to => 'issues#validate_recurrence_for_committee', :action => 'validate_recurrence_for_committee', :as => 'validate_recurrence_for_committee', :via => [:get, :post]
match '/issues/table_row', :to => 'issues#table_row', :action => 'table_row', :as => 'issue_table_row', :via => [:get, :post]
match '/issues/committee_data', :to => 'issues#committee_data', :action => 'committee_data', :as => 'issue_committee_data', :via => [:get, :post]
match '/issues/get_direction', :to => 'issues#get_direction', :action => 'get_direction', :as => 'issue_get_direction', :via => [:get, :post]
match '/issues/trackers_for_import', :to => 'issues#trackers_for_import', :action => 'trackers_for_import', :as => 'issue_trackers_for_import', :via => [:get, :post]
match '/issues/attributes_for_import', :to => 'issues#attributes_for_import', :action => 'attributes_for_import', :as => 'issue_attributes_for_import', :via => [:get, :post]
resources :issues do
  resources :checklists, :only => [:index, :create]
end

resources :checklists, :only => [:destroy, :update, :show] do
  member do
    put :done
  end
end

resources :project_templates