module IssueQueryPatch    
  include Redmine::SafeAttributes
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)          
    base.class_eval do
			self.available_columns = [
				QueryColumn.new(:id, :sortable => "#{Issue.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
				QueryColumn.new(:spmid, :sortable => "#{Issue.table_name}.spmid", :default_order => 'desc', :caption => '#'),
				QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
				QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :groupable => true),
				QueryColumn.new(:parent, :sortable => ["#{Issue.table_name}.root_id", "#{Issue.table_name}.lft ASC"], :default_order => 'desc', :caption => :field_parent_issue),
				QueryColumn.new(:status, :sortable => "#{IssueStatus.table_name}.position", :groupable => true),
				QueryColumn.new(:origin, :sortable => "#{Committee.table_name}.name", :groupable => true),
				QueryColumn.new(:task_type, :sortable => "#{Enumeration.table_name}.name", :groupable => true),
				QueryColumn.new(:direction, :sortable => "#{Direction.table_name}.name", :groupable => true),
				#QueryColumn.new(:vision, :sortable => false, :groupable => true),
				QueryColumn.new(:compliance_date, :sortable => "#{Issue.table_name}.compliance_date", :groupable => true),
				QueryColumn.new(:priority, :sortable => "#{IssuePriority.table_name}.position", :default_order => 'desc', :groupable => true),
				QueryColumn.new(:subject, :sortable => "#{Issue.table_name}.subject"),
				QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("authors")}, :groupable => true),
				QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => true),
				QueryColumn.new(:updated_on, :sortable => "#{Issue.table_name}.updated_on", :default_order => 'desc'),
				QueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name", :groupable => true),
				QueryColumn.new(:fixed_version, :sortable => lambda {Version.fields_for_order_statement}, :groupable => true),
				QueryColumn.new(:start_date, :sortable => "#{Issue.table_name}.start_date", :caption => :field_start_date_compliance_date),
				QueryColumn.new(:due_date, :sortable => "#{Issue.table_name}.due_date", :caption => :field_due_date_term),
				QueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours", :totalable => true),
				QueryColumn.new(:total_estimated_hours,
				:sortable => "COALESCE((SELECT SUM(estimated_hours) FROM #{Issue.table_name} subtasks" +
						" WHERE subtasks.root_id = #{Issue.table_name}.root_id AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)",
				:default_order => 'desc'),
				QueryColumn.new(:done_ratio, :sortable => "#{Issue.table_name}.done_ratio", :groupable => true),
				QueryColumn.new(:created_on, :sortable => "#{Issue.table_name}.created_on", :default_order => 'desc'),
				QueryColumn.new(:closed_on, :sortable => "#{Issue.table_name}.closed_on", :default_order => 'desc'),
				QueryColumn.new(:relations, :caption => :label_related_issues),
				QueryColumn.new(:description, :inline => false)
			]

			alias_method_chain :initialize_available_filters, :modification
			alias_method_chain :joins_for_order_statement, :modification
			alias_method_chain :issues, :modification
		end

		def sql_for_project_status_id_field(field, operator, value)
			sql_for_field('status', operator, value, Project.table_name, 'status')
		end

		def sql_for_project_type_id_field(field, operator, value)
			sql_for_field('project_type_id', operator, value, Project.table_name, 'project_type_id')
		end

		def sql_for_project_and_descendants_field(field, operator, value)
			projects = []
			Project.where(:id => value).map{ |p| projects += p.self_and_descendants}
			tree_projects = Project.project_tree(projects){|p| p}
			sql_for_field('id', operator, tree_projects.map{|p| p.id}, Project.table_name, 'id')
		end
  end
  module InstanceMethods

		# Returns the issues
		# Valid options are :order, :offset, :limit, :include, :conditions
		def issues_with_modification(options={})
			order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

			scope = Issue.visible.
					joins(:status, :project).
					where(statement).
					includes(([:status, :project] + (options[:include] || [])).uniq).
					where(options[:conditions]).
					order(order_option).
					joins(joins_for_order_statement(order_option.join(','))).
					limit(options[:limit]).
					offset(options[:offset])

			scope = scope.preload(:custom_values)
			if has_column?(:author)
				scope = scope.preload(:author)
			end

			issues = scope.to_a

			if has_column?(:spent_hours)
				Issue.load_visible_spent_hours(issues)
			end
			if has_column?(:total_spent_hours)
				Issue.load_visible_total_spent_hours(issues)
			end
			if has_column?(:relations)
				Issue.load_visible_relations(issues)
			end
			issues
		rescue ::ActiveRecord::StatementInvalid => e
			raise StatementInvalid.new(e.message)
		end

		def joins_for_order_statement_with_modification(order_options)
			joins = []

			if order_options
				if order_options.include?('authors')
					joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{queried_table_name}.author_id"
				end
				if order_options.include?('directions')
					joins << "LEFT OUTER JOIN #{Direction.table_name} directions ON directions.id = #{queried_table_name}.direction_id"
				end
				if order_options.include?('committees')
					joins << "LEFT OUTER JOIN #{Committee.table_name} committees ON committees.id = #{queried_table_name}.origin_id"
				end
				order_options.scan(/cf_\d+/).uniq.each do |name|
					column = available_columns.detect {|c| c.name.to_s == name}
					join = column && column.custom_field.join_for_order_statement
					if join
						joins << join
					end
				end
			end

			joins.any? ? joins.join(' ') : nil
		end
		def initialize_available_filters_with_modification
			principals = []
			subprojects = []
			versions = []
			categories = []
			issue_custom_fields = []

			if project
				principals += project.principals.visible
				unless project.leaf?
					subprojects = project.descendants.visible.to_a
					principals += Principal.member_of(subprojects).visible
				end
				versions = project.shared_versions.to_a
				categories = project.issue_categories.to_a
				issue_custom_fields = project.all_issue_custom_fields
			else
				if all_projects.any?
					principals += Principal.member_of(all_projects).visible
				end
				versions = Version.visible.where(:sharing => 'system').to_a
				issue_custom_fields = IssueCustomField.where(:is_for_all => true)
			end
			principals.uniq!
			principals.sort!
			principals.reject! {|p| p.is_a?(GroupBuiltin)}
			users = principals.select {|p| p.is_a?(User)}

			add_available_filter "status_id",
													 :type => :list_status, :values => IssueStatus.sorted.collect{|s| [s.name, s.id.to_s] }

			status_project = Array.new
			status_project[0] = [1, l(:project_status_active)]
			status_project[1] = [5, l(:project_status_closed)]
			status_project[2] = [9, l(:project_status_archived)]
			add_available_filter "project_status_id",
													 :type => :list, :values => status_project.collect {|v| [v[1].to_s, v[0].to_s]}

			add_available_filter "project_type_id",
													 :type => :list, :values => ProjectType.all.collect{|s| [s.name, s.id.to_s] }

			add_available_filter "spmid", :type => :text

			if project.nil?
				project_values = []
				if User.current.logged? && User.current.memberships.any?
					project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
				end
				project_values += (Project.project_tree(Project.visible.select{|p| p.status != Project::STATUS_CLOSED}){|p| p}).map{|d| [d.name.to_s, d.id.to_s]}
				add_available_filter("project_id",
														 :type => :list, :values => project_values
				) unless project_values.empty?

				add_available_filter("project_and_descendants",
														 :type => :list_optional, :values => project_values
				) unless project_values.empty?
			end

			add_available_filter "tracker_id",
													 :type => :list, :values => trackers.collect{|s| [s.name, s.id.to_s] }

			add_available_filter "direction_id",
													 :type => :list, :values => Direction.all.collect{|s| [s.name, s.id.to_s] }

			add_available_filter "priority_id",
													 :type => :list, :values => IssuePriority.all.collect{|s| [s.name, s.id.to_s] }

			author_values = []
			author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
			author_values += users.collect{|s| [s.name, s.id.to_s] }
			add_available_filter("author_id",
													 :type => :list, :values => author_values
			) unless author_values.empty?

			assigned_to_values = []
			assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
			assigned_to_values += (Setting.issue_group_assignment? ?
					principals : users).collect{|s| [s.name, s.id.to_s] }
			add_available_filter("assigned_to_id",
													 :type => :list_optional, :values => assigned_to_values
			) unless assigned_to_values.empty?

			group_values = Group.givable.visible.collect {|g| [g.name, g.id.to_s] }
			add_available_filter("member_of_group",
													 :type => :list_optional, :values => group_values
			) unless group_values.empty?

			role_values = Role.givable.collect {|r| [r.name, r.id.to_s] }
			add_available_filter("assigned_to_role",
													 :type => :list_optional, :values => role_values
			) unless role_values.empty?

			add_available_filter "fixed_version_id",
													 :type => :list_optional,
													 :values => versions.sort.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s] }

			add_available_filter "category_id",
													 :type => :list_optional,
													 :values => categories.collect{|s| [s.name, s.id.to_s] }

			add_available_filter "subject", :type => :text
			add_available_filter "description", :type => :text
			add_available_filter "created_on", :type => :date_past
			add_available_filter "updated_on", :type => :date_past
			add_available_filter "closed_on", :type => :date_past
			add_available_filter "start_date", :type => :date, :label => :field_start_date_compliance_date
			add_available_filter "compliance_date", :type => :date
			add_available_filter "due_date", :type => :date, :label => :field_due_date_term
			add_available_filter "estimated_hours", :type => :float
			add_available_filter "done_ratio", :type => :integer

			if User.current.allowed_to?(:set_issues_private, nil, :global => true) ||
					User.current.allowed_to?(:set_own_issues_private, nil, :global => true)
				add_available_filter "is_private",
														 :type => :list,
														 :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
			end

			if User.current.logged?
				add_available_filter "watcher_id",
														 :type => :list, :values => [["<< #{l(:label_me)} >>", "me"]]
			end

			if subprojects.any?
				add_available_filter "subproject_id",
														 :type => :list_subprojects,
														 :values => subprojects.collect{|s| [s.name, s.id.to_s] }
			end

			add_custom_fields_filters(issue_custom_fields)

			add_associations_custom_fields_filters :project, :author, :assigned_to, :fixed_version

			IssueRelation::TYPES.each do |relation_type, options|
				add_available_filter relation_type, :type => :relation, :label => options[:name]
			end
			add_available_filter "parent_id", :type => :tree, :label => :field_parent_issue
			add_available_filter "child_id", :type => :tree, :label => :label_subtask_plural

			add_available_filter "issue_id", :type => :integer, :label => :label_issue

			Tracker.disabled_core_fields(trackers).each {|field|
				delete_available_filter field
			}

			add_available_filter("origin_id",
													 :type => :list, :values => Committee.all.collect{|s| [s.name, s.id.to_s] }
			)

			add_available_filter("task_type_id",
													 :type => :list, :values => TaskType.all.collect{|s| [s.name, s.id.to_s] }
			)

			add_available_filter("direction_id",
													 :type => :list, :values => Direction.all.collect{|s| [s.name, s.id.to_s] }
			)

		end
  end
end