class AdvancedController < ApplicationController

  require 'uri'

  include QueriesHelper
  include SortHelper
  include ReportsHelper

  helper :sort
  helper :queries
  helper :reports

  before_filter :require_login
  before_filter :find_project, :only => [:index]
  before_filter :authorize, :find_issue_statuses

  def self.issues_by_direction(project, issues, delayed = false)
    count_and_group_by(:project => project, :association => :direction, :with_subprojects => true, :issues => issues, :delayed => delayed )
  end

  #@AIG:
  def self.issues_by_user(project, issues, delayed = false)
    count_and_group_by(:project => project, :association => :assigned_to, :with_subprojects => true, :issues => issues, :delayed => delayed )
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

  def index

    @query = AdvancedQuery.build_from_params(params, :name => '_')
    sort_init(@query.sort_criteria.empty? ? [['subject']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
    issues = @issues.map{|i| i.id.to_s}
    directions = @issues.map{|i| i.direction_id}

    #@AIG:
    assigned = @issues.map{|i| i.assigned_to_id}



    @field = "direction_id"
    @rows = directions.any? ? Direction.where(:id => directions).sort: Direction.all.sort



    #@AIG:
    @field2 = "assigned_to_id"
    @rows2 = assigned.any? ? User.where(:id => assigned).sort: User.all.sort

    #raise @rows2.inspect

    if issues.any?
      @data =  AdvancedController.issues_by_direction(@project,issues) || []
      @data_delay =  AdvancedController.issues_by_direction(@project,issues, true) || []

      #@AIG:
      @data2 =  AdvancedController.issues_by_user(@project,issues) || []
      @data_delay2 =  AdvancedController.issues_by_user(@project,issues, true) || []

    else
      @data = []
      @data_delay = []

      #@AIG:
      @data2 = []
      @data_delay2 = []
    end

    sort_rows_by_delayed

    @report_title = l(:field_direction)
    @report_title2 = l(:field_assigned_to)

    respond_to do |format|
      format.xlsx
      format.html
    end

  end

  def find_issue_statuses
    @statuses = IssueStatus.sorted.to_a
  end

  def sort_rows_by_delayed
    delayed_porcent = {}
    new_rows = {}

    @rows.each do |row|
      total_row = aggregate(@data, { 'direction_id' => row.id })
      total_delayed_row = aggregate(@data_delay, { 'direction_id' => row.id })
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


    #@AIG:
    delayed_porcent2 = {}
    new_rows2 = {}

    @rows2.each do |row|
      total_row2 = aggregate(@data2, { 'assigned_to_id' => row.id })
      total_delayed_row2 = aggregate(@data_delay2, { 'assigned_to_id' => row.id })
      delayed_porcent2[row.id] = total_row2 > 0 ? (total_delayed_row2.to_f/total_row2*100).round(2) : 0
      new_rows2[row.id] = row
    end

    #raise delayed_porcent2.inspect

    delayed_porcent2 = delayed_porcent2.sort_by { |k,v| v}.reverse.to_h

    if delayed_porcent2.any?
      @rows2 = []
      delayed_porcent2.each  do |row_id, v|
        @rows2 << new_rows2[row_id]
      end
    end

  end

end
