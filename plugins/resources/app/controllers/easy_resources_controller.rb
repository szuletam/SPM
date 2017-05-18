class EasyResourcesController < ApplicationController
  accept_api_auth :index, :issues, :projects#, :change_issue_relation_delay

  #before_filter :find_project_by_project_id, :if => Proc.new { params[:project_id].present? && params[:action] != "issues"}
	before_filter :find_project_by_project_id, :if => Proc.new { params[:project_id].present?}
  before_filter :replace_project, :if => Proc.new { params[:currprojectID].present? }
	before_filter :find_query, :only => [:issues, :projects]
  #before_filter :authorize, :if => Proc.new{ @project.present? }
  #before_filter :authorize_global, :if => Proc.new{ @project.nil? }

  menu_item :easy_resouces

  helper :queries
  helper :easy_resources
  if defined?(EasyExtensions)
    helper :easy_query
    include EasyQueryHelper
  end
  include SortHelper
   
	def replace_project
	  @project = Project.find(params[:currprojectID]) rescue nil if params[:currprojectID]
	end
	
  def index
    redirect_to :issues
  end

  def issues
    @start_date = @query.entity.minimum(:start_date)
    if @start_date.nil? && (x = @query.entity.minimum(:due_date))
      @start_date = x - 1.day
    end
    @start_date ||= Date.today
    @end_date = @query.entity.maximum(:start_date)

    respond_to do |format|
      format.html { render(:layout => !request.xhr?) }
      format.api do
        #if @project
        #  scope = if Setting.display_subprojects_issues?
        #    Version.where("id IN (#{@project.shared_versions.select(:id).to_sql}) OR id IN (#{@project.rolled_up_versions.visible.select(:id).to_sql})").uniq
        #  else
        #    @project.shared_versions
        #  end
        #  @fixed_versions = scope.reorder(:effective_date)
        #else
        #  fixed_version_scope = Version.visible.open
        #end
		
				@user = User.find(params[:projectID]) rescue User.current
				
				@users = [@user]
				
				user_ids = @query.issues.map{|i| i.assigned_to_id}.uniq.compact
				@user_dates = {}
				user_ids.each do |u|
					next if u != @user.id
					@user_dates[u] = {:start_date => nil, :due_date => nil}
				end
				
				@query.issues.each do |i|
					next if i.assigned_to_id.nil? || i.assigned_to_id != @user.id
					
					@user_dates[i.assigned_to_id][:project] ||= {}
					
					unless i.start_date.nil?
						@user_dates[i.assigned_to_id][:start_date] = i.start_date if @user_dates[i.assigned_to_id][:start_date].nil? || i.start_date < @user_dates[i.assigned_to_id][:start_date]
						@user_dates[i.assigned_to_id][:project][i.project_id] ||= {:start_date => nil, :due_date => nil, :max_date => nil}
						@user_dates[i.assigned_to_id][:project][i.project_id][:start_date] = i.start_date if @user_dates[i.assigned_to_id][:project][i.project_id][:start_date].nil? || i.start_date < @user_dates[i.assigned_to_id][:project][i.project_id][:start_date]
						@user_dates[i.assigned_to_id][:project][i.project_id][:max_date] = i.start_date if @user_dates[i.assigned_to_id][:project][i.project_id][:max_date].nil? || i.start_date > @user_dates[i.assigned_to_id][:project][i.project_id][:max_date]
					end
					
					unless i.due_date.nil?
						@user_dates[i.assigned_to_id][:due_date] = i.due_date if @user_dates[i.assigned_to_id][:due_date].nil? || i.due_date > @user_dates[i.assigned_to_id][:due_date]
						@user_dates[i.assigned_to_id][:project][i.project_id] ||= {:start_date => nil, :due_date => nil, :max_date => nil}
            #logger.info "anderson - #{i.id} - #{@user_dates[i.assigned_to_id][:project][i.project_id][:due_date].nil?} || #{(i.due_date > @user_dates[i.assigned_to_id][:project][i.project_id][:due_date]) rescue "null"} - #{i.due_date} - #{@user_dates[i.assigned_to_id][:project][i.project_id][:due_date]}"
            @user_dates[i.assigned_to_id][:project][i.project_id][:due_date] = i.due_date if @user_dates[i.assigned_to_id][:project][i.project_id][:due_date].nil? || i.due_date > @user_dates[i.assigned_to_id][:project][i.project_id][:due_date]
            #raise [@user_dates, "abc"].inspect if  i.due_date == Date.new(2016, 8, 10)
          end
					
					if i.due_date.nil? && i.start_date.nil?
            #logger.info "Entro aca #{@user_dates[i.assigned_to_id][:project][i.project_id][:due_date]}"

					  @user_dates[i.assigned_to_id][:project][i.project_id] ||= {:start_date => nil, :due_date => nil, :max_date => nil}
            if @user_dates[i.assigned_to_id][:project][i.project_id][:due_date].nil?
              @user_dates[i.assigned_to_id][:project][i.project_id][:due_date] = Date.today
            elsif (! @user_dates[i.assigned_to_id][:project][i.project_id][:due_date].nil? && Date.today > @user_dates[i.assigned_to_id][:project][i.project_id][:due_date])
              @user_dates[i.assigned_to_id][:project][i.project_id][:due_date] = Date.today
            end
					end
					

				end

				@entities_ids = []
				
				@version_ids = []
				@query.issues.each do |i|
					if i.assigned_to_id == @user.id
						@entities_ids << i.id
					@version_ids << i.project_id
					end
				end
				

				
				@fixed_versions = Project.where(:id => @version_ids).order("name").each{|p| p.class.module_eval { attr_accessor :user_id }; p.user_id = @user.id}

				@entities = Issue.where(:id => @entities_ids).order("subject")
				
				#if Project.column_names.include?('easy_is_easy_template')
				#  project_scope = Project.non_templates
				#  @fixed_versions = fixed_version_scope.where(Project.table_name => {:easy_is_easy_template => false}).reorder(:effective_date) if fixed_version_scope
				#else
				#  project_scope = Project.all
				#  @fixed_versions = fixed_version_scope.reorder(:effective_date) if fixed_version_scope
				#end

				#@projects = project_scope.visible.has_module(:issue_tracking).where(:id => @query.create_entity_scope(:includes => [:project, :status, :assigned_to, :fixed_version, :tracker, :priority, :custom_values]).pluck(:project_id))

				#@entities = @query.entities(:includes => [:project, :status, :assigned_to, :fixed_version, :tracker, :priority, :custom_values], :order => :start_date, :preload => [:project, :author, :assigned_to, :relations_from, :relations_to])

				#@relations = IssueRelation.joins(:issue_from => [:project, :status]).where(@query.statement)
				
				@relations = []
			
				#if !@project && Project.column_names.include?('easy_baseline_for_id')
				#  @fixed_versions = @fixed_versions.where(Project.table_name => {easy_baseline_for_id: nil})
				#  @relations = @relations.where(Project.table_name => {easy_baseline_for_id: nil})
				#end
      end
    end
  end

  def projects
    user_ids = @query.issues.map{|i| i.assigned_to_id}.uniq.compact
		
		@user_dates = {}
		user_ids.each do |u|
			@user_dates[u] = {:start_date => nil, :due_date => nil, :max_date => nil}
		end
    @users = User.active.where(:id => user_ids).order("firstname, lastname")
	
		@query.issues.each do |i|
			next if i.assigned_to.nil?
			
			unless i.start_date.nil?
				@user_dates[i.assigned_to_id][:start_date] = i.start_date if @user_dates[i.assigned_to_id][:start_date].nil? || i.start_date < @user_dates[i.assigned_to_id][:start_date]
        @user_dates[i.assigned_to_id][:max_date] = i.start_date if @user_dates[i.assigned_to_id][:max_date].nil? || i.start_date > @user_dates[i.assigned_to_id][:max_date]
      end
	  
			unless i.due_date.nil?
				@user_dates[i.assigned_to_id][:due_date] = i.due_date if @user_dates[i.assigned_to_id][:due_date].nil? || i.due_date > @user_dates[i.assigned_to_id][:due_date]
			end
			
			if i.due_date.nil? && i.start_date.nil?
				@user_dates[i.assigned_to_id][:due_date] = Date.today
			end
		end

		respond_to do |format|
      format.api
    end
  end

  def change_issue_relation_delay
    return render_403 unless User.current.allowed_to?(:manage_issue_relations, @project, :global => true)
    find_relation
    @relation.update_attributes(:delay => params[:delay])
    respond_to do |format|
      format.api { @relation.valid? ? render_api_ok : render_api_errors(@relation.errors.full_messages) }
    end
  end

  private

  def find_relation
    @relation = IssueRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def query_class
    EasyGantt::EasyGanttResourcesQuery
  end

  def find_query
    if defined?(EasyIssueGanttQuery)
      params[:force_use_from_session] = true
      retrieve_query(EasyIssueGanttQuery, :use_session_store => true)
      @query.export_formats = {}
      cond = 'project_id IS NULL'
      cond << " OR project_id = #{@project.id}" if @project
      @query = query_class.where(cond).find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = query_class.new(:name => '_')
      @query.project = @project
      @query.build_from_params(params)
      session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = nil
      @query = query_class.find_by_id(session[:query][:id]) if session[:query][:id]
      @query ||= query_class.new(:name => '_', :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names])
      @query.project = @project
    end
  end

  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    if @project.nil? || @project.module_enabled?(:easy_gantt)
      super
    else
      non_gantt_project = @project
      @project = nil
      if super(ctrl, action, true)
        @project = non_gantt_project
        true
      else
        false
      end
    end
  end
	
	 # Find project of id params[:project_id]
  def find_project_by_project_id
    @project = Project.find(params[:project_id]) rescue nil
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
