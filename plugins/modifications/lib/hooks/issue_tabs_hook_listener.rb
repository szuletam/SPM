class IssueTabsHookListener < Redmine::Hook::ViewListener
  render_on :view_issues_show_bottom, :partial => "common/history_tabs", :layout => false
end


