Redmine::Plugin.register :work_time do
  name 'Work Time plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  
  #menu :top_menu, :work_time, { :controller => 'work_time', :action => 'index' }, :caption => :label_work_time, :after => :easy_gantt, :if => Proc.new{|project| User.current.logged? }
  
  project_module :time_tracking do
	permission :work_time, { :work_time => [:index] }
	permission :view_users_work_time, { :work_time => [:index] }
  end
  
  menu :project_menu, :work_time, { :controller => 'work_time', :action => 'index' }, :caption => :label_work_time, :param => :project_id, :after => :easy_gantt
  
end
