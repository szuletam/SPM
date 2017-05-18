Redmine::Plugin.register :resources do
  name 'Resources plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  
  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |map|
      map.permission :issue_planning_simulation, {:planning => [:simulate]}
	end
  end
  
  menu :admin_menu, :user_calendars, { :controller => 'user_calendars', :action => 'index' }, :caption => :label_user_calendars
end

#Redmine::MenuManager.map :top_menu do |menu|
#  menu.push :easy_resources, :issues_easy_resources_path, {
#    :caption => :button_top_menu_easy_resources,
#    :parent => :others,
#    :after => :documents,
#    :if => Proc.new{|project| User.current.allowed_to_globally?(:view_easy_resources) }
#  }
#end
Redmine::MenuManager.map :project_menu do |menu|
  menu.push :easy_resources, { :controller => 'easy_resources', :action => 'issues' }, :param => :project_id, :after => :new_issue, :caption => :button_project_menu_easy_resources, :if => Proc.new{|project| User.current.allowed_to?(:view_easy_resources, project) }
end


Redmine::MenuManager.map(:project_menu).delete(:gantt)

Redmine::MenuManager.map :easy_resources do |menu|
  menu.push :task_control, 'javascript:void(0)', :param => :project_id, :caption => :button_edit, :html => {:icon => 'icon-edit'}, :if => Proc.new{|project| User.current.allowed_to?(:manage_issue_relations, project, :global => true)}
  menu.push :add_task, 'javascript:void(0)', :param => :project_id, :caption => Proc.new{ I18n.t(:label_new)}, :html => {:trial => true, :icon => 'icon-add'}, :if => Proc.new {|project| User.current.allowed_to?(:edit_easy_resources, project, :global => true) && User.current.allowed_to?(:add_issues, project) }
  menu.push :resource, Proc.new{|project| defined?(EasyUserAllocations) ? {:controller => 'user_allocation_gantt', :project_id => project} : nil}, :param => :project_id, :caption => :'easy_resources.button.resource_management', :html => {:trial => true, :icon => 'icon-stats'}, :if => Proc.new {|project| project.present? }
  menu.push :critical, 'javascript:void(0)', :param => :project_id, :caption => :'easy_resources.button.critical_path', :html => {:trial => true, :icon => 'icon-summary'}, :if => Proc.new {|project| project.present? }
  menu.push :baseline, 'javascript:void(0)', :param => :project_id, :caption => :'easy_resources.button.create_baseline', :html => {:trial => true, :icon => 'icon-projects icon-project'}, :if => Proc.new {|project| project.present? }
  menu.push :back, 'javascript:void(0)', :param => :project_id, :caption => :button_back, :html => {:icon => 'icon-back'}
  menu.push :save, 'javascript:void(0)', :param => :project_id, :caption => :button_save, :html => {:no_button => true, :class => 'button-positive button-1'}, :if => Proc.new{|project| User.current.allowed_to?(:edit_easy_resources, project, :global => true) && (User.current.allowed_to?(:edit_issues, project, :global => true) || User.current.allowed_to?(:manage_versions, project, :global => true))}
end

Redmine::AccessControl.map do |map|

  map.project_module :easy_resources do |pmap|
    pmap.permission :view_easy_resources, {:easy_resources => [:index, :issues, :projects]}, :global => true
    pmap.permission :edit_easy_resources, {:easy_resources => [:change_issue_relation_delay]}, :global => true
  end
end

begin
  Setting.where(:name => 'rest_api_enabled').update_all(:value => '1') if ActiveRecord::Base.connection.table_exists?.table_exists?(:settings)
rescue
  # do nothing => for cleanup installation & tests
end


