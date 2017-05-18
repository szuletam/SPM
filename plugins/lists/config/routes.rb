# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :directions
match '/context_menu/directions/', :to => 'context_menus#directions', :as => 'directions_context_menu', :via => [:get, :post]

resources :committees
match '/context_menu/committees/', :to => 'context_menus#committees', :as => 'committees_context_menu', :via => [:get, :pclsost]