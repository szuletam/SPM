# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'summaries', :to => 'summaries#index', :as => 'summaries', :via => [:get, :post]