# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/projects/:id/dashboard', :to => 'dashboard#index'
get 'dashboard', :to => 'dashboard#all_projects'
match 'dashboard/update_childrens', :to => 'dashboard#update_childrens', :as => 'update_childrens', :via => [:get, :post]
match 'dashboard/chart', :to => 'dashboard#chart', :as => 'chart', :via => [:get, :post]
match 'dashboard/reported_hours_chart', :to => 'dashboard#reported_hours_chart', :as => 'reported_hours_chart', :via => [:get, :post]
match 'dashboard/project_reported_hours_chart', :to => 'dashboard#project_reported_hours_chart', :as => 'project_reported_hours_chart', :via => [:get, :post]