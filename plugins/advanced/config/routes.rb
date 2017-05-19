# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get '/projects/:id/advanced', :to => 'advanced#index', :as => 'advanced'
