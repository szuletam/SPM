class AdvancedController < ApplicationController

  require 'uri'

  include QueriesHelper
  include SortHelper

  helper :sort
  helper :queries

  before_filter :require_login
  before_filter :find_project, :only => [:index]
  before_filter :find_tab, :only => [:index]
  before_filter :authorize, :find_issue_statuses

  TAB_DIRECTION = 'tab-directions'
  TAB_PROJECT = 'tab-projects'
  TAB_USERS = 'tab-users'

  def self.issues_by_direction(project, issues, delayed = false)
    count_and_group_by(:project => project, :association => :direction, :with_subprojects => true, :issues => issues, :delayed => delayed )
  end

  #@AIG:
  def self.issues_by_user(project, issues, delayed = false)
    count_and_group_by(:project => project, :association => :assigned_to, :with_subprojects => true, :issues => issues, :delayed => delayed )
  end

  def self.issues_by_project(project, issues, delayed = false)
    @statuses = IssueStatus.sorted.to_a
    data = count_and_group_by(:project => project, :association => :project, :with_subprojects => true, :issues => issues, :delayed => delayed )
    new_data = []
    project.self_and_descendants.each do |current_project|
      @statuses.each do |status|
        total = aggregate(data, { 'project_id' => current_project.id, 'status_id' => status.id })
        current_project.descendants.each do |descendant|
          total += aggregate(data, { 'project_id' => descendant.id, 'status_id' => status.id })
        end
        new_data << {'status_id' => status.id, 'closed' => status.is_closed?, 'project_id' => current_project.id, 'total' => total }
      end
    end
    new_data
  end

  def self.count_and_group_by(options)
    assoc = Issue.reflect_on_association(options[:association])
    select_field = assoc.foreign_key



    scope = Issue.joins(:project).where(:id => options[:issues], :projects => {:project_type_id => Setting.default_project_for_strategy.to_i})



    #si importa la fecha de retraso entonces se condiciona
    if options[:delayed]
      yesterday = (Date.today - 1).to_s(:db)
      scope = scope.open.where("issues.due_date <= '#{yesterday}'")
    end

    scope.visible(User.current, :project => options[:project], :with_subprojects => options[:with_subprojects]).
        joins(:status, assoc.name).
        group(:status_id, :is_closed, select_field).
        count.
        map do |columns, total|
      status_id, is_closed, field_value = columns
      is_closed = ['t', 'true', '1'].include?(is_closed.to_s)
      {
          "status_id" => status_id.to_s,
          "closed" => is_closed,
          select_field => field_value.to_s,
          "total" => total.to_s
      }
    end

    #raise select_field.inspect
  end

  def tab_directions issues
    directions = @issues.map{|i| i.direction_id}
    @field = "direction_id"
    @rows = directions.any? ? Direction.where(:id => directions).sort: Direction.all.sort

    if issues.any?
      @data =  AdvancedController.issues_by_direction(@project,issues) || []
      @data_delay =  AdvancedController.issues_by_direction(@project,issues, true) || []
    else
      @data = []
      @data_delay = []
    end

    sort_rows_by_delayed 'direction_id'

    @report_title = l(:field_direction)
  end

  def tab_projects issues
    projects_with_issues = @issues.map{|i| i.project_id}

    projects = []

    @project.self_and_descendants.each do |project|
      in_projects = false
      project.self_and_descendants.each do |descendant|
        if projects_with_issues.include? descendant.id
          in_projects = true
          break
        end
      end
      if in_projects
        projects << project.id
      end
    end

    @field = "project_id"
    @rows = projects.any? ? Project.project_tree(Project.where(:id => projects)){|p| p}: Project.project_tree(Project.all){|p| p}

    if issues.any?
      #@AIG:
      @data =  AdvancedController.issues_by_project(@project,issues) || []
      @data_delay =  AdvancedController.issues_by_project(@project,issues, true) || []
    else
      @data = []
      @data_delay = []
    end

    @report_title = l(:field_project)

  end

  def tab_users issues
    assigned = @issues.map{|i| i.assigned_to_id}
    @field = "assigned_to_id"
    @rows = assigned.any? ? User.where(:id => assigned).sort: User.all.sort

    if issues.any?
      @data =  AdvancedController.issues_by_user(@project,issues) || []
      @data_delay =  AdvancedController.issues_by_user(@project,issues, true) || []
    else
      @data = []
      @data_delay = []
    end

    sort_rows_by_delayed 'assigned_to_id'

    @report_title = l(:field_assigned_to)

  end

  def index

    @query = AdvancedQuery.build_from_params(params, :name => '_')
    sort_init(@query.sort_criteria.empty? ? [['subject']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
    issues = @issues.map{|i| i.id.to_s}

    if tab_is_users?
       tab_users issues
    elsif tab_is_project?
      tab_projects issues
    else
      tab_directions issues
    end

    respond_to do |format|
      format.xlsx
      format.html
    end

  end

  def find_issue_statuses
    @statuses = IssueStatus.sorted.to_a
  end

  def sort_rows_by_delayed field
    delayed_porcent = {}
    new_rows = {}

    @rows.each do |row|
      total_row = aggregate(@data, { field => row.id })
      total_delayed_row = aggregate(@data_delay, { field => row.id })
      delayed_porcent[row.id] = total_row > 0 ? (total_delayed_row.to_f/total_row*100).round(2) : nil
      new_rows[row.id] = row
    end

    delayed_porcent = delayed_porcent.sort_by { |k,v| v}.reverse.to_h

    if delayed_porcent.any?
      @rows = []
      delayed_porcent.each  do |row_id, v|
        @rows << new_rows[row_id]
      end
    end

  end

  def find_tab
    @tab = params[:tab] if params[:tab]
    @tab ||= TAB_DIRECTION
  end

end
