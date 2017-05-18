Redmine::Plugin.register :evm do
  name 'Evm plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  
  project_module :evm do
    permission :ratios, { :ratios => [:index] }, :public => true
  end
  menu :project_menu, :ratios,
       { :controller => 'ratios', :action => 'index' },
       :caption => :project_module_evm, :after => :easy_gantt
end
