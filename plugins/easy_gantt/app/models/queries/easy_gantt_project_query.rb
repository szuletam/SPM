class EasyGanttProjectQuery < Query

  attr_accessor :opened_project

  self.queried_class = Project

  self.available_columns = [
    QueryColumn.new(:name, sortable: "#{Project.table_name}.name"),
    QueryColumn.new(:status, sortable: "#{Project.table_name}.status"),
    QueryColumn.new(:created_on, sortable: "#{Project.table_name}.created_on"),
    QueryColumn.new(:updated_on, sortable: "#{Project.table_name}.updated_on"),
  ]

  def initialize(*args)
    super
    self.filters ||= {"status"=>{:operator=>"=", :values=>["1"]}}
    self.filters ||= {}
  end

  def default_columns_names
    [:name]
  end

  def initialize_available_filters
    status = Array.new
    status[0] = [1, l(:project_status_active)]
    status[1] = [5, l(:project_status_closed)]
    status[2] = [9, l(:project_status_archived)]
    add_available_filter 'name', type: :text
    add_available_filter 'status', :type => :list, :values => status.collect {|v| [v[1].to_s, v[0].to_s]}
    add_available_filter 'created_on', type: :date_past
    add_available_filter 'updated_on', type: :date_past
  end

  def from_params(params)
    build_from_params(params)
  end

  def to_params
    params = { set_filter: 1, type: self.class.name, f: [], op: {}, v: {} }

    filters.each do |filter_name, opts|
      params[:f] << filter_name
      params[:op][filter_name] = opts[:operator]
      params[:v][filter_name] = opts[:values]
    end

    params[:c] = column_names
    params
  end

  def to_partial_path
    'easy_gantt/easy_queries/show'
  end

  def entities(options={})
    scope = Project.active.visible

    if Project.column_names.include? 'easy_baseline_for_id'
      scope = scope.where(Project.table_name => { easy_baseline_for_id: nil })
    end

    scope = scope.includes(options[:includes]).
                  references(options[:includes]).
                  preload(options[:preload]).
                  where(statement).
                  where(options[:conditions]).
                  order(options[:order])

    if opened_project
      scope = scope(projects: { id: opened_project.id })
    end

    scope.to_a
  end

  def without_opened_project
    _opened_project = opened_project
    self.opened_project = nil
    yield self
  ensure
    self.opened_project = _opened_project
  end

end
