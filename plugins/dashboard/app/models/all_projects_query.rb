class AllProjectsQuery < ProjectQuery

  attr_accessor :current_project

  ISSUE_FILTERS = ["project_and_descendants","created_on", "updated_on", "closed_on", "start_date", "due_date"]


  def sql_for_project_and_descendants_field(field, operator, value)
    projects = []
    Project.where(:id => value).map{ |p| projects += p.self_and_descendants}
    tree_projects = Project.project_tree(projects){|p| p}
    sql_for_field('project_id', operator, tree_projects.map{|p| p.id}, Issue.table_name, 'project_id')
  end

  def sql_for_issues(filters)
    wheres = []
    table_name = Issue.table_name
    filters.each do |filter, data|
      if filter == 'project_and_descendants'
        wheres << sql_for_project_and_descendants_field(filter, data[:operator], data[:values])
      elsif ISSUE_FILTERS.include? filter
        wheres << sql_for_field(filter, data[:operator], data[:values], table_name, filter)
      end
    end
    return "(#{wheres.join(') AND (')})" unless wheres.empty?
    ''
  end

  def initialize_available_filters
    add_available_filter "project_and_descendants", :type => :list, :values => (Project.project_tree(Project.visible.select{|p| p.status != Project::STATUS_CLOSED}){|p| p}).map{|c| [c.name, c.id.to_s]}
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "closed_on", :type => :date_past
    add_available_filter "start_date", :type => :date
    add_available_filter "due_date",  :type => :date
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters = {}
  end

  end