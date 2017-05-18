class AdvancedQuery < IssueQuery

  def sql_for_project_and_descendants_field(field, operator, value)
    projects = []
    Project.where(:id => value).map{ |p| projects += p.self_and_descendants}
    tree_projects = Project.project_tree(projects){|p| p}
    sql_for_field('id', operator, tree_projects.map{|p| p.id}, Project.table_name, 'id')
  end

  def initialize_available_filters
    projects = project.self_and_descendants
    principals = []
    subprojects = []
    versions = []
    categories = []

    principals += project.principals.visible
    unless project.leaf?
      subprojects = Project.project_tree(project.self_and_descendants.visible){|p| p}
      principals += Principal.member_of(subprojects).visible
    end
    projects.each do |p|
      versions += p.shared_versions.to_a
      categories += p.issue_categories.to_a
    end
    issue_custom_fields = project.all_issue_custom_fields

    principals.uniq!
    principals.sort!
    principals.reject! {|p| p.is_a?(GroupBuiltin)}
    users = principals.select {|p| p.is_a?(User)}

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

    add_available_filter "category_id",
                         :type => :list_optional,
                         :values => categories.collect{|s| [s.name, s.id.to_s] }

    add_available_filter "subject", :type => :text
    add_available_filter "description", :type => :text
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "closed_on", :type => :date_past
    add_available_filter "start_date", :type => :date
    add_available_filter "due_date", :type => :date
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
      add_available_filter "project_and_descendants",
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

    Tracker.disabled_core_fields(trackers).each {|field|
      delete_available_filter field
    }
  end

  def build_from_params(params)
    self.project = Project.find(params[:id])
    projects = project.self_and_descendants
    versions = []
    projects.each do |p|
      versions += p.shared_versions.to_a
    end

    super
    self
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters = {}
  end

end