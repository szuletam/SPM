# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :holidays
match '/context_menu/holidays/', :to => 'context_menus#holidays', :as => 'holidays_context_menu', :via => [:get, :post]