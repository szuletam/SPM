class WorkTimeQuery < IssueQuery
  
  attr_accessor :selected_user
  
  def set_user(user)
	self.selected_user = user
    self.filters['assigned_to_id'] = {:operator => "=", :values => [user.id.to_s]}
  end
  
  def initialize_available_filters
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
    
	if project.nil?
      project_values = []
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("project_id",
        :type => :list, :values => project_values
      ) unless project_values.empty?
    end
	
    add_available_filter "status_id",
      :type => :list_status, :values => IssueStatus.sorted.collect{|s| [s.name, s.id.to_s] }

    add_available_filter "tracker_id",
      :type => :list, :values => trackers.collect{|s| [s.name, s.id.to_s] }
    add_available_filter "priority_id",
      :type => :list, :values => IssuePriority.all.collect{|s| [s.name, s.id.to_s] }

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("author_id",
      :type => :list, :values => author_values
    ) unless author_values.empty?

    assigned_to_values = []
    #assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    
	principals = principals.select{|u| u.id == selected_user.id} if Setting.issue_group_assignment? && ! User.current.allowed_to?(:view_users_work_time, (project.nil? ? nil : project), :global => (project.nil? ? true : false))
	users = users.select{|u| u.id == selected_user.id} if !Setting.issue_group_assignment? && ! User.current.allowed_to?(:view_users_work_time, (project.nil? ? nil : project), :global => (project.nil? ? true : false))
	
	assigned_to_values += (Setting.issue_group_assignment? ?
                              principals : users).collect{|s| [s.name, s.id.to_s] }
	add_available_filter("assigned_to_id",
      :type => :list_optional, :values => assigned_to_values
    ) unless assigned_to_values.empty?
	
	if project
      add_available_filter "fixed_version_id",
        :type => :list_optional,
        :values => versions.sort.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s] }
	
      add_available_filter "category_id",
        :type => :list_optional,
        :values => categories.collect{|s| [s.name, s.id.to_s] }
	end
	
    add_available_filter "subject", :type => :text
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "closed_on", :type => :date_past
    add_available_filter "start_date", :type => :date
    add_available_filter "due_date", :type => :date
    add_available_filter "estimated_hours", :type => :float
    add_available_filter "done_ratio", :type => :integer
  end
  
  def issues(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
    scope = Issue.
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
  
end