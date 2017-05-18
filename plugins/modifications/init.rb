require 'redmine'
require_dependency 'hooks/sidebar_hook_listener'
require_dependency 'hooks/theme_hook_listener'
require_dependency 'hooks/issue_tabs_hook_listener'
require_dependency 'hooks/views_layouts_hook'
require_dependency 'hooks/views_issues_hook'
require_dependency 'task_type'
require_dependency 'project_type'

Rails.configuration.to_prepare do
  require 'compatibility/open_struct_patch'
end

Redmine::Plugin.register :modifications do
  name 'Modifications plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''
  author_url 'http://aigroup.com.co'
  
  permission :modifications, { :issues => [:get_done_ratio] }, :public => true
  permission :view_project_menu, {}
  
  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |map|
      map.permission :view_checklists,            {:checklists => [:show, :index]}
      map.permission :done_checklists,            {:checklists => :done}
      map.permission :edit_checklists,            {:checklists => [:done, :create, :destroy, :update]}
      map.permission :create_recurrent_issue,     {}
      map.permission :close_foreing_issue,     {}
	end
  end
  
  #menu :admin_menu, :project_templates, { :controller => 'project_templates', :action => 'index' }, :caption => :label_project_templates, :after => :projects
  
  Rails.configuration.to_prepare do  
    ApplicationHelper.send(:include, ApplicationHelperPatch)
  end
  
  Rails.configuration.to_prepare do  
    ContextMenusController.send(:include, ContextMenusControllerPatch)
  end

  Rails.configuration.to_prepare do
    ReportsController.send(:include, ReportsControllerPatch)
  end

  Rails.configuration.to_prepare do
    SearchController.send(:include, SearchControllerPatch)
  end

  Rails.configuration.to_prepare do
    UsersController.send(:include, UsersControllerPatch)
  end
  
  Rails.configuration.to_prepare do  
    IssueImport.send(:include, IssueImportPatch)
  end

  Rails.configuration.to_prepare do
    MyHelper.send(:include, MyHelperPatch)
  end
  
  Rails.configuration.to_prepare do  
    Issue.send(:include, IssuePatch)
  end

  Rails.configuration.to_prepare do
    Mailer.send(:include, MailerPatch)
  end
  
  Rails.configuration.to_prepare do  
    IssueQuery.send(:include, IssueQueryPatch)
  end
  
  Rails.configuration.to_prepare do  
    IssuesController.send(:include, IssuesControllerPatch)
  end

  Rails.configuration.to_prepare do
    IssueStatusesController.send(:include, IssueStatusesControllerPatch)
  end
  
  Rails.configuration.to_prepare do  
    IssuesHelper.send(:include, IssuesHelperPatch)
  end
  
  Rails.configuration.to_prepare do  
    Member.send(:include, MemberPatch)
  end
  
  Rails.configuration.to_prepare do  
    MembersController.send(:include, MembersControllerPatch)
  end
  
  Rails.configuration.to_prepare do  
    Project.send(:include, ProjectPatch)
  end
  
  Rails.configuration.to_prepare do  
    ProjectsController.send(:include, ProjectsControllerPatch)
  end
  
  Rails.configuration.to_prepare do  
    ProjectsHelper.send(:include, ProjectsHelperPatch)
  end
  
  Rails.configuration.to_prepare do  
    QueriesHelper.send(:include, QueriesHelperPatch)
  end
  
  Rails.configuration.to_prepare do  
    TimeEntry.send(:include, TimeEntryPatch)
  end
  
  Rails.configuration.to_prepare do  
    TimelogController.send(:include, TimelogControllerPatch)
  end
  
  Rails.configuration.to_prepare do  
    Version.send(:include, VersionPatch)
  end
  
  Rails.configuration.to_prepare do  
    WelcomeController.send(:include, WelcomeControllerPatch)
  end

  Rails.configuration.to_prepare do
    Setting.send(:include, SettingPatch)
  end

  Rails.configuration.to_prepare do
    User.send(:include, UserPatch)
  end

end
