Redmine::Plugin.register :lists do
  name 'Lists plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  
  menu :admin_menu, :directions, { :controller => 'directions', :action => 'index' }, :caption => :label_directions
  
  menu :admin_menu, :positions, { :controller => 'positions', :action => 'index' }, :caption => :label_positions

  menu :admin_menu, :committees, { :controller => 'committees', :action => 'index' }, :caption => :label_committees

  
  Rails.configuration.to_prepare do  
    ContextMenusController.send(:include, ContextMenusListsPatch)
  end
end
