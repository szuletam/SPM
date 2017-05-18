# AI Group SAS
module MyHelperPatch
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do
		alias_method_chain :issuesassignedtome_items, :modification
		alias_method_chain :issuesreportedbyme_items, :modification
	end
	
  end
  module InstanceMethods
		def issuesassignedtome_items_with_modification
			Issue.where(:tracker_id => Setting.default_application_for_task).joins(:project).where("#{Project.table_name}.status != #{Project::STATUS_CLOSED}").visible.open.
					assigned_to(User.current).
					limit(10).
					includes(:status, :project, :tracker, :priority).
					references(:status, :project, :tracker, :priority).
					order('due_date ASC')
		end

		def issuesreportedbyme_items_with_modification
			Issue.visible
					.where(:tracker_id => Setting.default_application_for_task)
					.where(:author_id => User.current.id).
					limit(10).
					includes(:status, :project, :tracker).
					references(:status, :project, :tracker).
					order("#{Issue.table_name}.updated_on DESC")
		end
  end
end