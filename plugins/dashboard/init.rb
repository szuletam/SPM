Redmine::Plugin.register :dashboard do
  name 'Dashboard plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :all_projects,{:controller=>'dashboard',:action=>'all_projects'},{:caption => :label_dashboard, :if=>Proc.new{|p| User.current.allowed_to_globally?(:view_dashboard)}}
end

Redmine::AccessControl.map do |map|
  map.project_module :dashboard do |pmap|
    pmap.permission :view_dashboard, {:dashboard => [:all_projects]}, :global => true
  end
end


