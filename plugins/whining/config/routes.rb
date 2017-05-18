# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/whinings/sending/', :to => 'whinings#sending', :as => 'whinings_sending', :via => [:get, :post]