# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources 'user_calendars'

match '/user_calendars/get_calendar_table', :to => 'user_calendars#get_calendar_table', :action => 'get_calendar_table', :as => 'get_calendar_table', :via => [:get, :post]
match '/planning/:id/simulate', :to => 'planning#simulate', :action => 'simulate', :as => 'planning_simulate', :via => [:get, :post]
match '/resources/projects', :to => 'resources#projects', :action => 'projects', :as => 'project_resources', :via => [:get, :post]
match '/resources/:project_id/issues', :to => 'resources#issues', :action => 'issues', :as => 'issue_resources', :via => [:get, :post]


scope '(projects/:project_id)' do
  resource :easy_resources, :controller => 'easy_resources', :only => [:index, :items_data] do
    member do
      get 'issues'
      get 'projects'
      #put 'relation/:id(.:format)', :to => 'easy_gantt#change_issue_relation_delay'
    end
  end
end
