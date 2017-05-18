class WorkTimeController < ApplicationController
  
  helper 'timelog'
  
  helper 'queries'
  
  helper 'issues'
  
  include WorkTimeHelper
  
  include QueriesHelper
  
  include SortHelper
  
  before_filter :find_project, :find_date, :find_users, :find_user, :find_projects, :find_included_issues, :only => [:index, :create, :update, :destroy, :include_issue, :remove_issue]
  
  before_filter :set_data, :except => [:new, :edit, :form, :create, :update, :load_issues, :include_issue, :remove_issue]
  
  before_filter :require_login
  
  before_filter :init_time_entry, :only => [:new, :edit]
  
  def include_issue
	work_time_issue = WorkTimeIssue.new
	work_time_issue.issue_id = params[:issue_id]
	work_time_issue.user_id = params[:user_id]
	work_time_issue.save
	set_data
	find_included_issues
	respond_to do |format|
	  format.js {}
	end
  end
  
  def remove_issue
	work_time_issues = WorkTimeIssue.where(:issue_id => params[:issue_id], :user_id => @user.id)
	work_time_issues.map{|wti| wti.destroy}
	set_data
	find_included_issues
	respond_to do |format|
	  format.js {}
	end
  rescue
    set_data
  	 respond_to do |format|
      format.js {}
    end
  end
  
  def create
	@time_entry = TimeEntry.new
	@time_entry.safe_attributes = params[:time_entry]
	begin
	  @time_entry.user_id = params[:time_entry][:user_id]
	rescue
	  @time_entry.user_id = User.current.id
	end
	
	begin
	  @time_entry.issue.init_journal(User.current, '')
	  @time_entry.issue.done_ratio = params[:issue][:done_ratio]
	  @time_entry.issue.save
	rescue; end
	
	@time_entry.save
	set_data
    respond_to do |format|
	  format.js {}
	end
  end
  
  def update
    begin
	  @time_entry = TimeEntry.find(params[:time_entry][:id])
	rescue
      @time_entry = TimeEntry.new
	end
	@time_entry.safe_attributes = params[:time_entry]
	begin
	  @time_entry.user_id = params[:time_entry][:user_id]
	rescue
	  @time_entry.user_id = User.current.id
	end
	
	begin
	  @time_entry.issue.init_journal(User.current, '')
	  @time_entry.issue.done_ratio = params[:issue][:done_ratio]
	  @time_entry.issue.save
	rescue; end
	
	@time_entry.save
	set_data
    respond_to do |format|
	  format.js {}
	end
  end
  
  def new
	@include_project = (params[:project].to_s == "1" ? true : false)
	render :layout => false
  end
  
  def edit
    @include_project = (params[:project].to_s == "1" ? true : false)
    @time_entries = @issue.time_entries.where("user_id" => params[:user_id], "spent_on" => params[:spent_on])
	render :layout => false
  end
  
  def form
    @include_project = (params[:project].to_s == "1" ? true : false)
    @time_entry = TimeEntry.find(params[:id])
	render :layout => false
  end
  
  def destroy
    @include_project = (params[:project].to_s == "1" ? true : false)
	@time_entry = TimeEntry.find(params[:id])
	@time_entry.destroy
	set_data
	respond_to do |format|
	  format.js {}
	end
  end
  
  def index
    respond_to do |format|
	  format.csv  { send_data(csv_report, :type => 'text/csv; header=present', :filename => (month_name(@date.month) + " - #{@date.year}" +  " - #{@user.name}.csv")) }
	  format.html
	end
  end
  
  def load_issues
    find_project
	@issues = @project.issues.order("subject").select(&:leaf?)
    respond_to do |format|
	  format.js {}
	end
  end
  
  private
  
  def anchored_issues
    issues = []
		roles = [0]
	
		no_projects_ids = Member.joins(:member_roles).where("#{MemberRole.table_name}.role_id" => roles).where(:user_id => @user.id).map{|m| m.project_id}.uniq.compact
		no_projects_ids = [0] if no_projects_ids.empty?
		project_ids = [0]
    projects = Project.where(["id IN (?)", project_ids]).where(["id NOT IN(?)", no_projects_ids])

		projects.each do |p|
	  	issues += p.issues.select(&:leaf?).map{|i| i.id}
		end
		issues
  end
  
  def init_time_entry
    @issue = Issue.find(params[:issue_id])
	@time_entry = TimeEntry.new
	@time_entry.issue_id = @issue.id
	@time_entry.user_id = params[:user_id]
	@time_entry.project_id = @issue.project_id
	@time_entry.spent_on = params[:spent_on]
  end
  
  def set_data
	@date_to_validate = nil
	@query = WorkTimeQuery.new(:name => "_")
	@query.project = @project.nil? ? nil : @project
	@query.set_user(@user)
	@query.build_from_params(params)
	
    sort_init(@query.sort_criteria.empty? ? [
						["#{Project.table_name}.name", "desc"], 
						["#{Project.table_name}.subject", "desc"]
					] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a
	
	@limit = Setting.issues_export_limit.to_i
	
	# Own Time Entries
	scope = TimeEntry
	scope = scope.where(["spent_on BETWEEN ? AND ?", @date.beginning_of_month, @date.end_of_month])
	#scope = scope.where(:project_id => @project.id) unless @project.nil?
	scope = scope.where(:user_id => @user.id)
	scope = scope.order(:spent_on)
	issue_ids = scope.select("issue_id").map{|t| t.issue_id}
	#@project_time_entries = scope.where("issue_id IS NOT NULL").group(["spent_on","project_id"]).sum(:hours)
	time_entry_scope = scope
	
	closed_statuses = IssueStatus.where(:is_closed => true).select("id")
	
	work_time_issue_ids = WorkTimeIssue.where(:user_id => @user.id).select("issue_id")
	
	# Own Issues
	scope = Issue
	scope = scope.where(["(assigned_to_id = ?) OR #{Issue.table_name}.id IN (?) OR #{Issue.table_name}.id IN (?)", @user.id, issue_ids, work_time_issue_ids])
	#scope = scope.where(:project_id => @project.id) unless @project.nil?
	scope = scope.select(:id, :subject, :project_id, :tracker_id, :status_id, :due_date, :parent_id, :rgt, :lft, :is_private, :author_id, :assigned_to_id)
	scope = scope.joins(:project)
	scope = scope.order( "#{Project.table_name}.name", "#{Issue.table_name}.subject")
	
	if @query.valid?
	  tmp_issues = scope.all.map{|i| i.id}
	  conditions = "#{Issue.table_name}.id IN (#{tmp_issues.size == 0 ? "NULL" : tmp_issues.join(',')})"

	  @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => ["#{Project.table_name}.name", "#{Issue.table_name}.subject"], :conditions => conditions)
	  
	  tmp_issues_all = @issues.map{|i| i.id} + issue_ids 
	  
	  conditions_all = "#{Issue.table_name}.id IN (#{tmp_issues_all.size == 0 ? "NULL" : tmp_issues_all.join(',')})"
	  
	  tmp_assigned = @query.filters["assigned_to_id"]
	  
	  @query.filters.delete("assigned_to_id")
	  
	  @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => ["#{Project.table_name}.name", "#{Issue.table_name}.subject"], :conditions => conditions_all)
	  
	  @query.filters["assigned_to_id"] = tmp_assigned
  
	  tmp_issues_all = @issues.map{|i| i.id} + anchored_issues
	  
	  conditions_all = "#{Issue.table_name}.id IN (#{tmp_issues_all.size == 0 ? "NULL" : tmp_issues_all.join(',')})"
	  
	  @query.filters.delete("assigned_to_id")
	  
	  @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => ["#{Project.table_name}.name", "#{Issue.table_name}.subject"], :conditions => conditions_all)
	 
	  @query.filters["assigned_to_id"] = tmp_assigned
	  
	  @issues = @issues.size == 0 ? 0 : @issues
	  
	  work_time_issue_ids = work_time_issue_ids == 0 ? 0 : work_time_issue_ids
	  if work_time_issue_ids != 0 && @issues != 0
	    @issues = Issue.where(:id => @issues.map{|i| i.id} + work_time_issue_ids.map{|i| i.issue_id}).joins(:project).order("#{Project.table_name}.name", "#{Issue.table_name}.id")
	  elsif @issues != 0
	    @issues = Issue.where(:id => @issues.map{|i| i.id}).joins(:project).order("#{Project.table_name}.name", "#{Issue.table_name}.id")
	  elsif work_time_issue_ids != 0
	    @issues = Issue.where(:id => work_time_issue_ids.map{|i| i.issue_id}).joins(:project).order("#{Project.table_name}.name", "#{Issue.table_name}.id")
	  else
	    @issues = []
	  end
	else
	  @issues = scope.all
	end
	if @project
		tmp_issues_all = @issues.map{|i| i.id} + anchored_issues
		@issues = Issue.where(:id => tmp_issues_all)
	end

	@issues = @issues.select{	|i| i.leaf? || issue_ids.include?(i.id)}

	time_entry_scope = time_entry_scope.where(:issue_id => @issues.map{|i| i.id})
	@project_time_entries = time_entry_scope.group(["spent_on","project_id"]).sum(:hours)
	time_entry_scope = time_entry_scope.group(["spent_on","issue_id"]).sum(:hours)
	@time_entries = time_entry_scope
	
	scope = Project.where(:id => @issues.map{|i| i.project_id}).select(:name, :id, :status, :identifier).order(:name).all
	@projects = {}
	scope.map{|p| @projects[p.id] = p}
	
	scope = Holiday.where(["date BETWEEN ? AND ?", @date.beginning_of_month, @date.end_of_month])
	@holidays = []
	scope.map{|h| @holidays << h.date}
	
	scope = Tracker.all
	@trackers = {}
	scope.map{|t| @trackers[t.id] = t}
	
	scope = IssueStatus.all
	@statuses = {}
	scope.map{|s| @statuses[s.id] = t}
	
	@draw_projects = []
  end
  
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    @project = nil
  end
  
  def find_included_issues
	@work_time_issues = []
	#if @project
	  #work_time_issues = WorkTimeIssue.joins(:issue).where("#{Issue.table_name}.project_id" => @project.id).where(:user_id => @user.id).select("issue_id", "id")
	#else
	  work_time_issues = WorkTimeIssue.where(:user_id => @user.id).select("issue_id", "id")
	#end
	
	work_time_issues.each{|wti| @work_time_issues << wti.issue_id}
  end

  def find_date
	@date = params[:date].to_date
  rescue
	@date = Date.today
  end
  
  def find_user
    @user = User.find(params[:user_id]) if params[:user_id]
	@user = User.find(params[:v][:assigned_to_id].first)
  rescue
    @user = User.current
  end
  
  def find_users
	@users = @project.principals.order(:firstname)
  rescue
    @users = User.active.order(:firstname).all
  end
  
  def find_projects
	if @project
	  @user_projects = Project.where(:id => [@project.id]).order("name")
	elsif User.current.admin?
	  @user_projects = Project.active.order("name").all
	else
	  @user_projects = @user.projects.order("name")
	end
  rescue
	@user_projects = User.current.projects.order("name")
  end
  
end
