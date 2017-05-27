class SummariesController < ApplicationController

  include QueriesHelper
  include SortHelper

  helper :sort
  helper :queries

  before_filter :require_login

  def vars_security

    @for_user = params[:for_user] && !params[:for_user].blank? ? params[:for_user] : nil
    @for_direction = params[:for_direction] && !params[:for_direction].blank? ? params[:for_direction] : nil
    @for_user = nil if @for_user.blank?
    @for_direction = nil if @for_direction.blank? || @for_user
    @for_general = @for_user || @for_direction ? nil : User.current.id.to_s

    #se convierte el id en objeto
    if @for_user
      @for_user = User.find(@for_user) rescue nil
    end
    if @for_direction
      @for_direction = Direction.find(@for_direction) rescue nil
    end
    if @for_general
      @for_general = User.find(@for_general) rescue nil
    end
  end

  def get_directions user
    if user.admin? || user.general?
      Direction.order(:name)
    elsif user.director?
      [user.direction]
    else
      []
    end
  end

  def get_users user
    if user.admin? || user.general?
      User.active.visible.where(:id => Member.select(:user_id).map(&:user_id).uniq).order(:firstname, :lastname)
    elsif user.director?
      User.active.visible.where(:id => Member.select(:user_id).map(&:user_id).uniq).where(:direction => user.direction).order(:firstname, :lastname)
    else
      [User.current]
    end
  end

  def index

    vars_security

    @user = User.current
    @directions = get_directions @user
    @users = get_users @user
    @my_projects = Project.visible.select{|p| p.status != Project::STATUS_CLOSED && !p.is_committee?}
    @data = {:ta => [], :tr => [], :tro => [], :tr7 => [], :tro7 => [], :tr8 => [], :tro8 => [], :tr30 => [], :tro30 => []}
    @query = SummariesQuery.build_from_params(params, :name => '_')
    sort_init(@query.sort_criteria.empty? ? [['subject']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?

      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version])

      if @issues.any?

        #join y where para solo tener en cuenta el tipo de actividades que se tienen en cuenta para la planificación
        join_tracker = "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
        where_tracker = "#{Tracker.table_name}.is_in_roadmap = 1"


        today  = Date.today#scope = Issue.open.visible.where(:tracker_id => Setting.default_application_for_task.to_i).where(:id => @issues.map{|i| i.id.to_s})
        scope  = Issue.open.visible.joins(:project).joins(join_tracker).where(where_tracker).where(:id => @issues.map{|i| i.id.to_s}).where(:status_id => [1,9]).where(:projects => {:project_type_id => Setting.default_project_for_strategy.to_i})

        #raise scope.to_sql.inspect

        #time = Time.now
        #day = time.wday # es otra forma de determinar el dia
        #@temp = (time + 259200).strftime("%Y/%m/%d")
        #raise  @temp.inspect

        scope2 = Issue.open.visible.joins(:project).joins(join_tracker).where(where_tracker).where(:id => @issues.map{|i| i.id.to_s}).where(:status_id => 5).where(:projects => {:project_type_id => Setting.default_project_for_strategy.to_i})

        my_project = params[:v] && params[:v][:project_and_descendants] && params[:v][:project_and_descendants][0] ? params[:v][:project_and_descendants][0] : ''
        if my_project != ''
        elsif @for_user
          scope = scope.where(:assigned_to => @for_user)
          scope2 = scope2.where(:assigned_to => @for_user)
        elsif @for_direction
          scope = scope.where(:direction => @for_direction)
          scope2 = scope2.where(:direction => @for_direction)
        end

        #ta: tareas abiertas
        #tr: tareas retrasadas
        #tro: tareas retrasadas para otro

        ta = scope.where("#{Issue.table_name}.due_date IS NOT NULL OR #{Issue.table_name}.due_date != ''")

        #tareas retrasadas
        tr = scope.where("#{Issue.table_name}.due_date < '#{today.to_s}'")
        tro = scope2.where("#{Issue.table_name}.due_date < '#{today.to_s}'")

        #raise tro.to_sql.inspect

        #tareas que vencen en 7 dias
        tr7 = scope.where("#{Issue.table_name}.due_date BETWEEN '#{today.to_s}' AND  '#{(today + 7).to_s}'")
        tro7 = scope2.where("#{Issue.table_name}.due_date BETWEEN '#{today.to_s}' AND  '#{(today + 7).to_s}'")

        #tareas que vencen entre 8 y 30 dias
        tr8 = scope.where("#{Issue.table_name}.due_date BETWEEN '#{(today + 8).to_s}' AND  '#{(today + 30).to_s}'")
        tro8 = scope2.where("#{Issue.table_name}.due_date BETWEEN '#{(today + 8).to_s}' AND  '#{(today + 30).to_s}'")

        #tareas que vencen en 30+ dias
        tr30 = scope.where("#{Issue.table_name}.due_date > '#{(today + 30).to_s}'")
        tro30 = scope2.where("#{Issue.table_name}.due_date > '#{(today + 30).to_s}'")

        @data = {
            :ta => ta,
            :tr => tr,
            :tro => tro,
            :tr7 => tr7,
            :tro7 => tro7,
            :tr8 => tr8,
            :tro8 => tro8,
            :tr30 => tr30,
            :tro30 => tro30,
        }

      end

    end

    respond_to do |format|
      format.html { render :template => 'summaries/index', :layout => !request.xhr? }
      format.pdf  { send_file_headers! :type => 'application/pdf', :filename => 'scrum.pdf' }
    end

  end

end
