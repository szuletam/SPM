class DashboardController < ApplicationController

  require 'uri'

  include QueriesHelper
  include SortHelper

  helper :sort
  helper :queries

  before_filter :require_login
  before_filter :find_project, :only => [:index, :update_childrens]

  def index
    yesterday = (Date.today - 1).to_s(:db)
    @query = DashboardQuery.build_from_params(params, :name => '_')
    sort_init(@query.sort_criteria.empty? ? [['subject']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    where = @query.statement
    id_projects = @project.self_and_descendants.map{|p| p.id}

    #join y where para solo tener en cuenta el tipo de actividades que se tienen en cuenta para la planificación
    join_tracker = "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
    where_tracker = "#{Tracker.table_name}.is_in_roadmap = 1"

    hours_issues = TimeEntry.visible.joins(:issue, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group(:issue_id, :subject).sum(:hours).collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    issues_status = Issue.visible.joins(:status, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{IssueStatus.table_name}.id", "#{IssueStatus.table_name}.name").count.collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    issues_versions = Issue.visible.joins(:fixed_version, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{Version.table_name}.id", "#{Version.table_name}.name").count.collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    issues_trackers = Issue.visible.joins(:tracker, :project).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{Tracker.table_name}.id", "#{Tracker.table_name}.name").count.collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    hours_user = TimeEntry.visible.joins(:issue, :user, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).where("#{User.table_name}.status = 1").group("#{User.table_name}.id", "CONCAT(#{User.table_name}.firstname,' ', #{User.table_name}.lastname)").sum("#{TimeEntry.table_name}.hours").collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    #issues_user = Issue.joins(:assigned_to, :project).joins(join_tracker).where(where_tracker).where(where).where("#{Project.table_name}.id" => id_projects).where("#{User.table_name}.status = 1").group("#{Principal.table_name}.id", "CONCAT(#{Principal.table_name}.firstname,' ', #{Principal.table_name}.lastname)").count.collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    issues_direction = Issue.visible.joins(:direction, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{Direction.table_name}.id", "#{Direction.table_name}.name").count.collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    issues_open_direction = Issue.visible.open.joins(:direction, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).group("#{Direction.table_name}.id", "#{Direction.table_name}.name").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
    issues_closed_direction = {}
    issues_open_direction.each do |dir, n|
      nt = issues_direction.include?(dir) ? issues_direction[dir] : 0
      issues_closed_direction[dir] = (nt - n)*100/nt if nt != 0
    end
    issues_closed_direction = issues_closed_direction.sort_by { |k,v| v}.reverse.to_h
    delayeds_direction = Issue.visible.open.where("issues.due_date <= '#{yesterday}'").joins(:direction, :project).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{Direction.table_name}.id", "#{Direction.table_name}.name").count.collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h


    #covertir delayeds_direction a porcentajes
    delayeds_direction = delayeds_direction.map{|c,v| [c,v*100/issues_direction[c]]}.sort_by { |k,v| v}.reverse.to_h if issues_direction.any?

    hours_activity = TimeEntry.visible.joins(:activity, :project, :issue).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{TimeEntryActivity.table_name}.id", "#{TimeEntryActivity.table_name}.name").sum("#{TimeEntry.table_name}.hours").collect{|k, v| [k[1], v]}.sort_by { |k,v| v}.reverse.to_h
    sql = "SELECT SUM(COALESCE(issues.estimated_hours, 0)) AS estimated_hours, "
    sql += " SUM((COALESCE(issues.done_ratio, 0) * COALESCE(issues.estimated_hours, 0) )/100) AS advanced_hours,"
    sql += " (SUM((COALESCE(done_ratio, 0) * COALESCE(issues.estimated_hours, 0) )/100) * 100 )/(SUM(COALESCE(issues.estimated_hours, 0))) AS advanced_porcentage"
    sql += " FROM issues #{join_tracker} INNER JOIN projects ON issues.project_id = projects.id WHERE #{where_tracker} AND (issues.parent_id IS NULL OR issues.parent_id = '')"
    sql += " AND #{where}" unless where.blank?
    advanced_porcentage = ActiveRecord::Base.connection.execute(sql).to_a[0].map{|v| v.round(2)} rescue []

    reported_hours = project_reported_hours_chart_data(params, 'spent_on')

    issues_status_direction_data = Issue.joins(:direction, :project, :status).joins(join_tracker).where(where_tracker).where("#{Project.table_name}.id" => id_projects).where(where).group("#{Direction.table_name}.id", "#{Direction.table_name}.name","#{IssueStatus.table_name}.id", "#{IssueStatus.table_name}.name").count.sort_by { |k,v| v}.reverse.to_h

    issues_status_direction = sort_issues_status_direction issues_status_direction_data, issues_direction

    @charts = []
    set_chart @charts, 'issues_advance', l(:label_issues_advance), l(:label_issues_advance), l(:label_advance_percentage), advanced_porcentage, 'gauge'
    set_chart @charts, 'hours_issues', l(:label_hours_activities), l(:label_hours_activities), l(:label_reported_hours), hours_issues, 'donut'
    set_chart @charts, 'issues_status', l(:label_status_issues), l(:label_status_issues), l(:label_number_issues), issues_status, 'donut'
    set_chart @charts, 'issues_versions', l(:label_version_issues), l(:label_version_issues), l(:label_number_issues), issues_versions, 'bar'
    #set_chart @charts, 'issues_trackers', l(:label_tracker_issues), l(:label_tracker_issues), l(:label_number_issues), issues_trackers, 'bar'
    set_chart @charts, 'hours_user', l(:label_hours_users), l(:label_hours_users), l(:label_reported_hours), hours_user, 'donut'
    #set_chart @charts, 'issues_user', l(:label_issues_user), l(:label_issues_user), l(:label_assigned_activites), issues_user, 'bar'
    set_chart @charts, 'issues_direction', l(:label_weight_direction), l(:label_weight_direction), l(:label_assigned_activites), issues_direction, 'donut'
    #set_chart @charts, 'issues_status_direction', l(:label_issues_direction), l(:label_issues_direction), l(:label_number_issues), issues_status_direction, 'stack'
    set_chart @charts, 'issues_closed_direction', l(:label_issues_direction), l(:label_issues_direction), l(:label_porcent_advanced_activites), issues_closed_direction, 'bar'
    set_chart @charts, 'delayeds_direction', l(:label_delayeds_direction), l(:label_delayeds_direction), l(:label_delayed_activites), delayeds_direction, 'bar'
    set_chart @charts, 'hours_activity', l(:label_hours_activities_type), l(:label_hours_activities_type), l(:label_reported_hours), hours_activity, 'donut'
    set_chart @charts, 'reported_hours', l(:label_acum_reported_hours), l(:label_acum_reported_hours), l(:label_reported_hours), reported_hours, 'line'

    @params = params
  end

  def all_projects
    yesterday = (Date.today - 1).to_s(:db)
    @query = AllProjectsQuery.build_from_params(params, :name => '_')
    sort_init(@query.sort_criteria.empty? ? [['name']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      where_issue = @query.sql_for_issues(@query.filters)
      projects = Project.project_tree(Project.visible.select{|p| p.status != Project::STATUS_CLOSED}){|p| p}

      hours_projects = {}
      all_projects_id = []
      projects.each do |project|
        all_projects_id.concat project.self_and_descendants.map { |p| p.id }
        value = TimeEntry.visible.joins(:project, :issue).
            where(where_issue).where("#{Project.table_name}.id" => project.self_and_descendants.map { |p| p.id }).
            sum(:hours)
        hours_projects[[project.id, project.name]] = value unless value.nil? || value == 0
      end
      hours_projects = hours_projects.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h

      #join y where para solo tener en cuenta el tipo de actividades que se tienen en cuenta para la planificación
      join_tracker = "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
      where_tracker = "#{Tracker.table_name}.is_in_roadmap = 1"

      issues_status = Issue.visible.joins(:status, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).group("#{IssueStatus.table_name}.id", "#{IssueStatus.table_name}.name").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      issues_direction = Issue.visible.joins(:direction, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).group("#{Direction.table_name}.id", "#{Direction.table_name}.name").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      issues_open_direction = Issue.visible.joins(:direction, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects, :status_id => 1).group("#{Direction.table_name}.id", "#{Direction.table_name}.name").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      issues_closed_direction = {}
      issues_open_direction.each do |dir, n|
        nt = issues_direction.include?(dir) ? issues_direction[dir] : 0
        issues_closed_direction[dir] = (nt - n)*100/nt if nt != 0
      end
      issues_closed_direction = issues_closed_direction.sort_by { |k,v| v}.reverse.to_h
      delayeds_direction = Issue.visible.open.where("issues.due_date <= '#{yesterday}'").joins(:direction, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).group("#{Direction.table_name}.id", "#{Direction.table_name}.name").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h

      #covertir delayeds_direction a porcentajes
      delayeds_direction = delayeds_direction.map{|c,v| [c,v*100/issues_direction[c]]}.sort_by { |k,v| v}.reverse.to_h if issues_direction.any?

      issues_trackers = Issue.visible.joins(:tracker, :project).where(where_tracker).where(where_issue).where(:project => projects).group("#{Tracker.table_name}.id", "#{Tracker.table_name}.name").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      hours_user = TimeEntry.visible.joins(:issue, :user, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).where("#{User.table_name}.status = 1").group("#{User.table_name}.id", "CONCAT(#{User.table_name}.firstname,' ', #{User.table_name}.lastname)").sum("#{TimeEntry.table_name}.hours").collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      #issues_user = Issue.joins(:assigned_to, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).where("#{User.table_name}.status = 1").group("#{Principal.table_name}.id", "CONCAT(#{Principal.table_name}.firstname,' ', #{Principal.table_name}.lastname)").count.collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      hours_activity = TimeEntry.visible.joins(:activity, :project, :issue).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).group("#{TimeEntryActivity.table_name}.id", "#{TimeEntryActivity.table_name}.name").sum("#{TimeEntry.table_name}.hours").collect { |k, v| [k[1], v] }.sort_by { |k,v| v}.reverse.to_h
      sql = "SELECT SUM(COALESCE(estimated_hours, 0)) AS estimated_hours,"
      sql += " SUM((COALESCE(done_ratio, 0) * COALESCE(estimated_hours, 0) )/100) AS advanced_hours,"
      sql += " (SUM((COALESCE(done_ratio, 0) * COALESCE(estimated_hours, 0) )/100) * 100 )/(SUM(COALESCE(estimated_hours, 0))) AS advanced_porcentage"
      sql += " FROM issues #{join_tracker} WHERE #{where_tracker} AND project_id IN ('#{projects.map { |p| p.id.to_s }.join("','")}') AND (parent_id IS NULL OR parent_id = '')"
      sql += " AND #{where_issue}" unless where_issue.blank?
      advanced_porcentage = ActiveRecord::Base.connection.execute(sql).to_a[0].map { |v| v.round(2) } rescue []

      reported_hours = reported_hours_chart_data(params, 'spent_on')

      issues_status_direction_data = Issue.visible.joins(:status, :direction, :project).joins(join_tracker).where(where_tracker).where(where_issue).where(:project => projects).group("#{Direction.table_name}.id", "#{Direction.table_name}.name","#{IssueStatus.table_name}.id", "#{IssueStatus.table_name}.name").count.sort_by { |k,v| v}.reverse.to_h

      issues_status_direction = sort_issues_status_direction issues_status_direction_data, issues_direction

      @charts = []
      set_chart @charts, 'project_advance', l(:label_project_advance), l(:label_project_advance), l(:label_advance_percentage), advanced_porcentage, 'gauge'
      set_chart @charts, 'hours_projects', l(:label_hours_projects), l(:label_hours_projects), l(:label_reported_hours), hours_projects, 'donut'
      set_chart @charts, 'issues_status', l(:label_status_issues), l(:label_status_issues), l(:label_number_issues), issues_status, 'donut'
      #set_chart @charts, 'issues_trackers', l(:label_tracker_issues), l(:label_tracker_issues), l(:label_number_issues), issues_trackers, 'bar'
      set_chart @charts, 'hours_user', l(:label_hours_users), l(:label_hours_users), l(:label_reported_hours), hours_user, 'donut'
      #set_chart @charts, 'issues_user', l(:label_issues_user), l(:label_issues_user), l(:label_assigned_activites), issues_user, 'bar'
      set_chart @charts, 'issues_direction', l(:label_weight_direction), l(:label_weight_direction), l(:label_assigned_activites), issues_open_direction, 'donut'
      #set_chart @charts, 'issues_status_direction', l(:label_issues_direction), l(:label_issues_direction), l(:label_number_issues), issues_status_direction, 'stack'
      set_chart @charts, 'issues_closed_direction', l(:label_issues_direction), l(:label_issues_direction), l(:label_porcent_advanced_activites), issues_closed_direction, 'bar'
      set_chart @charts, 'delayeds_direction', l(:label_delayeds_direction), l(:label_delayeds_direction), l(:label_porcent_delayed_activites), delayeds_direction, 'bar'
      set_chart @charts, 'hours_activity', l(:label_hours_activities_type), l(:label_hours_activities_type), l(:label_reported_hours), hours_activity, 'donut'
      set_chart @charts, 'reported_hours', l(:label_acum_reported_hours), l(:label_acum_reported_hours), l(:label_reported_hours), reported_hours, 'line'

      initialize_monthly_report

      @params = params
    end
  end

  def update_childrens
    render :partial => 'children_projects', :locals => {:project => Project.find(params[:id])}
  end

  def initialize_monthly_report
    monthly_reports = MonthlyReport.between("#{Date.today.year.to_s}-01-01", "#{(Date.today - 1.months).year.to_s}-#{(Date.today - 1.months).month.to_s}-31").order('direction_id ASC, report_date ASC')
    @mrs = {}
    monthly_reports.each do |mr|
      @mrs[mr.direction] = [] unless @mrs[mr.direction]
      @mrs[mr.direction] << mr
    end

    MonthlyReport.get_last_month.each do |direction_id, mr|
      @mrs[mr.direction] = [] unless @mrs[mr.direction]
      @mrs[mr.direction] << mr
    end

    @mrs
  end

  def sort_issues_status_direction issues_status_direction_data = {}, issues_direction = {}

    issues_status_direction_without_sort = {}
    if issues_status_direction_data.any?
      issues_status_direction_data.each do |ied, v|
        issues_status_direction_without_sort[ied[1]] = {} unless issues_status_direction_without_sort[ied[1]]
        issues_status_direction_without_sort[ied[1]][ied[3]] = v
      end
    end

    if issues_direction.any?
      issues_status_direction = {}
      issues_direction.each do |direction, value|
        issues_status_direction[direction] = issues_status_direction_without_sort[direction]
      end
      issues_status_direction
    else
      issues_status_direction_without_sort
    end
  end


  def set_chart(charts, div_id, filename, title, serie_name, data, chart)
    charts << {
        :div_id => div_id,
        :filename => filename,
        :title => title,
        :serie_name => serie_name,
        :data => data,
        :chart => chart,
    }
    charts
  end

  def chart
    params["data"] = params["data"].sort_by { |k,v| v}.reverse.to_h if params["data"] && params["data"].any?
    params[:chart] = params[:new_chart]
    respond_to do |format|
      format.js { render :partial => "dashboard/charts/#{params[:new_chart]}", :locals => params}
    end
  end

  def reported_hours_chart
    reported_hours = reported_hours_chart_data(params['old_params'], params['time_interval'])
    respond_to do |format|
      format.js { render :partial => "dashboard/charts/line",
                         :locals => {
                             :div_id => 'reported_hours',
                             :filename => l(:label_acum_reported_hours),
                             :title => l(:label_acum_reported_hours),
                             :serie_name => l(:label_reported_hours),
                             :data => reported_hours,
                             :chart => 'line',
                         }}
    end
  end

  def project_reported_hours_chart
    reported_hours = project_reported_hours_chart_data(params['old_params'], params['time_interval'])
    respond_to do |format|
      format.js { render :partial => "dashboard/charts/line",
                         :locals => {
                             :div_id => 'reported_hours',
                             :filename => l(:label_acum_reported_hours),
                             :title => l(:label_acum_reported_hours),
                             :serie_name => l(:label_reported_hours),
                             :data => reported_hours,
                             :chart => 'line',
                         }}
    end
  end

  def reported_hours_chart_data(params, time_interval)

    @query = AllProjectsQuery.build_from_params(params, :name => '_')

    where_issue = @query.sql_for_issues(@query.filters)

    projects = Project.project_tree(Project.visible.select{|p| p.status != Project::STATUS_CLOSED}){|p| p}

    all_projects_id = []
    projects.each do |project|
      all_projects_id.concat project.self_and_descendants.map { |p| p.id }
    end

    sql  = "SELECT t1.#{time_interval}, SUM(t2.acum) as acum, t1.tyear"
    sql += "  FROM (SELECT SUM(hours), #{time_interval}, tyear"
    sql +=       "  FROM time_entries"
    sql +=       "    INNER JOIN issues"
    sql +=       "      ON issues.id = time_entries.issue_id"
    sql +=       "  WHERE issues.project_id IN ('#{all_projects_id.join("','")}')"
    sql +=       "    AND #{where_issue}" unless where_issue.blank?
    sql +=       "  GROUP BY #{time_interval}, tyear) t1"
    sql += "    INNER JOIN (SELECT SUM(hours) as acum, #{time_interval}, tyear"
    sql +=             "    FROM time_entries"
    sql +=             "      INNER JOIN issues"
    sql +=             "        ON issues.id = time_entries.issue_id"
    sql +=             "    WHERE issues.project_id IN ('#{all_projects_id.join("','")}')"
    sql +=             "      AND #{where_issue}" unless where_issue.blank?
    sql +=             "    GROUP BY #{time_interval}, tyear) t2"
    sql +=   "    ON t2.#{time_interval} <= t1.#{time_interval}"
    sql += "  GROUP BY t1.#{time_interval}, t1.tyear;"

    #raise sql.inspect
    reported_hours = ActiveRecord::Base.connection.execute(sql).to_a.map{ |row|
      if time_interval == 'tmonth'
        ["#{(Date.new(row[2],1,1) + row[0].months).strftime("%Y-%m-%d")}|#{(Date.new(row[2],1,1) + (row[0] + 1).months - 1.days).strftime("%Y-%m-%d")}", row[1]]
      elsif time_interval == 'tweek'
        ["#{(Date.new(row[2],1,1) + row[0].weeks).strftime("%Y-%m-%d")}|#{(Date.new(row[2],1,1) + (row[0] + 1).weeks - 1.days).strftime("%Y-%m-%d")}", row[1]]
      else
        [row[0].strftime("%Y-%m-%d"), row[1]]
      end
    }.sort_by { |k,v| v}.reverse.to_h
    return reported_hours if reported_hours.blank?
    goal_reported_hours = Issue.where(:project_id => all_projects_id).where(where_issue).sum("COALESCE(estimated_hours,0)")
    reported_hours["goal"] = goal_reported_hours
    reported_hours

  end

  def project_reported_hours_chart_data(params, time_interval)

    @query = DashboardQuery.build_from_params(params, :name => '_')
    where = @query.statement

    sql  = "SELECT t1.#{time_interval}, SUM(t2.acum) as acum, t1.tyear"
    sql += "  FROM (SELECT SUM(hours), #{time_interval}, tyear"
    sql +=       "  FROM time_entries"
    sql +=       "    INNER JOIN issues"
    sql +=       "      ON issues.id = time_entries.issue_id"
    sql +=       "    INNER JOIN projects"
    sql +=       "      ON issues.project_id = projects.id"
    sql +=       "  WHERE #{where}" unless where.blank?
    sql +=       "  GROUP BY #{time_interval}, tyear) t1"
    sql += "    INNER JOIN (SELECT SUM(hours) as acum, #{time_interval}, tyear"
    sql +=             "    FROM time_entries"
    sql +=             "      INNER JOIN issues"
    sql +=             "        ON issues.id = time_entries.issue_id"
    sql +=             "      INNER JOIN projects"
    sql +=             "        ON issues.project_id = projects.id"
    sql +=             "    WHERE #{where}" unless where.blank?
    sql +=             "    GROUP BY #{time_interval}, tyear) t2"
    sql +=   "    ON t2.#{time_interval} <= t1.#{time_interval}"
    sql += "  GROUP BY t1.#{time_interval}, t1.tyear;"


    reported_hours = ActiveRecord::Base.connection.execute(sql).to_a.map{ |row|
      if time_interval == 'tmonth'
        ["#{(Date.new(row[2],1,1) + row[0].months).strftime("%Y-%m-%d")}|#{(Date.new(row[2],1,1) + (row[0] + 1).months - 1.days).strftime("%Y-%m-%d")}", row[1]]
      elsif time_interval == 'tweek'
        ["#{(Date.new(row[2],1,1) + row[0].weeks).strftime("%Y-%m-%d")}|#{(Date.new(row[2],1,1) + (row[0] + 1).weeks - 1.days).strftime("%Y-%m-%d")}", row[1]]
      else
        [row[0].strftime("%Y-%m-%d"), row[1]]
      end
    }.sort_by { |k,v| v}.reverse.to_h
    return reported_hours if reported_hours.blank?
    goal_reported_hours = Issue.joins(:project).where(where).sum("COALESCE(estimated_hours,0)")
    reported_hours["goal"] = goal_reported_hours
    reported_hours
  end

end
