Redmine::Plugin.register :advanced do
  name 'Advanced plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  menu :project_menu, :advanced, { :controller => 'advanced', :action => 'index' }, :caption => :label_advanced
  project_module :advanced do
    permission :advanced, :advanced => :index
  end
end
