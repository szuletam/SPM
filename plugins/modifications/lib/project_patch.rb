# AI Group SAS
module ProjectPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do
	  include Redmine::SafeAttributes
	  safe_attributes 'cpi', 'spi', 'project_start_date',
							'project_due_date',
							'project_done_ratio', 'is_template', 'project_type_id',
							'overview', 'activity'

		belongs_to :project_type

	  alias_method_chain :copy_issues, :modification

		validate do |project|
			trackers_ids = project.trackers.map{|t| t.id}
			if project.is_strategy? && trackers_ids.include?(Setting.default_application_for_committee.to_i)
				project.errors[:base] << I18n::t(:error_strategy_not_have_issue_committee)
			end
			if project.is_committee? && trackers_ids.include?(Setting.default_application_for_task.to_i)
				project.errors[:base] << I18n::t(:error_committee_not_have_issue_task)
			end
			if !project.is_committee? && !project.is_strategy? && (trackers_ids.include?(Setting.default_application_for_committee.to_i) || trackers_ids.include?(5)) #TODO: no quemar el 5
				project.errors[:base] << I18n::t(:error_normal_just_have_issue_task)
			end
		end
	  def self.next_identifier
		p = Project.where("is_template" => 0).order('id DESC').first
		p.nil? ? nil : p.identifier.to_s.succ
		end

		def self.roots_visibles
			roots = []
			Project.visible.sort_by(&:lft).each do |project|
				if roots.last.nil?
					roots << project
				elsif !project.is_descendant_of?(roots.last)
					roots << project
				end
			end
			roots
		end

	end

	def is_committee?
		self.project_type_id == Setting.default_project_for_committee.to_i rescue false
		end
	def is_strategy?
		self.project_type_id == Setting.default_project_for_strategy.to_i rescue false
	end

	def assignable_users_including_all_subprojects
		if Setting.display_subprojects_issues?
			types = ['User']
			types << 'Group' if Setting.issue_group_assignment?

			@assignable_users_including_all_subprojects ||= Principal.
				active.
				joins(:members => :roles).
				where(:type => types, :roles => {:assignable => true}).
				where(:members => {:project_id => Project.where("lft >= ? AND rgt <= ?", lft, rgt)}).uniq.sorted
		else
			assignable_users
		end
	end
	
	def set_identifier(ident)
	  self.identifier = ident
	end
	
	def curr_ancestors
		ret = []
		self.ancestors.map{|as|
			ret << as unless as.is_template
		}
		ret 
	end
	
	def is_template?
	  self.is_template
	end
	
	def indicator
	  Indicator.new(self.id)
	end
	
	def versions_with_indicators
	  indicator = Indicator.new self.id
	  versions = indicator.get_versions self.id
	  return versions
	end
	
	def tree_class
	  css = ""
	  parent = self.parent
	  while(! parent.nil?)
		css += "project-#{parent.id} "
		parent = parent.parent
	  end
	  css
	end
	
  end
  module InstanceMethods
	def copy_issues_with_modification(project)
      copy_issues_without_modification(project)
      issues.each{ |issue| issue.copy_checklists(issue.copied_from)}
    end
  end
end