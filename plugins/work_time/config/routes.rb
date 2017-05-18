# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'work_time', :to => 'work_time#index', :as => 'work_time', :via => [:get, :post], :defaults => { :format => 'html' }
match 'work_time/new', :to => 'work_time#new', :as => 'work_time_new', :via => [:get, :post]
match 'work_time/create', :to => 'work_time#create', :as => 'work_time_create', :via => [:get, :post]
match 'work_time/edit', :to => 'work_time#edit', :as => 'work_time_edit', :via => [:get, :post]
match 'work_time/update', :to => 'work_time#update', :as => 'work_time_update', :via => [:get, :post, :put]
match 'work_time/form', :to => 'work_time#form', :as => 'work_time_form', :via => [:get, :post]
match 'work_time/destroy', :to => 'work_time#destroy', :as => 'work_time_destroy', :via => [:get, :post]
match 'work_time/load_issues', :to => 'work_time#load_issues', :as => 'work_time_load_issues', :via => [:get, :post]
match 'work_time/include_issue', :to => 'work_time#include_issue', :as => 'work_time_include_issue', :via => [:get, :post]
match 'work_time/remove_issue', :to => 'work_time#remove_issue', :as => 'work_time_remove_issue', :via => [:get, :post]