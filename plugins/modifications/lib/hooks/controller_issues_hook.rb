class ControllerIssuesHook < Redmine::Hook::ViewListener
  def controller_issues_edit_after_save(context = {})
	#if (Setting.issue_done_ratio == "issue_field") && RedmineChecklists.settings[:issue_done_ratio]
	#  Checklist.recalc_issue_done_ratio(context[:issue].id)
	#end
  end
end
