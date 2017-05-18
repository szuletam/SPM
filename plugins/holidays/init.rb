Redmine::Plugin.register :holidays do
  name 'Holidays plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  
  menu :admin_menu, :holidays, { :controller => 'holidays', :action => 'index' }, :caption => :label_holidays
  
  Rails.configuration.to_prepare do  
    ContextMenusController.send(:include, ContextMenusHolidaysControllerPatch)
  end
end
