module ProjectsControllerPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do    
	  include QueriesHelper
	  include SortHelper
	  helper :sort
	  helper :projects
	  alias_method_chain :index, :modification
	  alias_method_chain :new, :modification
	  alias_method_chain :create, :modification
	  alias_method_chain :copy, :modification
	  alias_method_chain :modules, :modification
    end
  end
  module InstanceMethods
    def copy_with_modification
      @issue_custom_fields = IssueCustomField.sorted.to_a
      @trackers = Tracker.sorted.to_a
      @source_project = Project.find(params[:id])
	  @source_project.is_template = false #Dont create as template
      if request.get?
        @project = Project.copy_from(@source_project)
        @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
      else
        Mailer.with_deliveries(params[:notifications] == '1') do
          @project = Project.new
          @project.safe_attributes = params[:project]
          if @project.copy(@source_project, :only => params[:only])
            flash[:notice] = l(:notice_successful_create)
            redirect_to settings_project_path(@project)
          elsif !@project.new_record?
            # Project was created
            # But some objects were not copied due to validation failures
            # (eg. issues from disabled trackers)
            # TODO: inform about that
            redirect_to settings_project_path(@project)
          end
        end
      end
    rescue ActiveRecord::RecordNotFound
      # source_project not found
      render_404
	end

		def modules_with_modification
			@project.update_attribute(:overview, (params[:overview] ? true : false ))
			@project.update_attribute(:activity, (params[:activity] ? true : false ))
			@project.enabled_module_names = params[:enabled_module_names]
			flash[:notice] = l(:notice_successful_update)
			redirect_to settings_project_path(@project, :tab => 'modules')
		end

    def create_with_modification
      @issue_custom_fields = IssueCustomField.sorted.to_a
      @trackers = Tracker.sorted.to_a
      @project = Project.new
      @project.safe_attributes = params[:project]

      if @project.save
        unless User.current.admin?
          @project.add_default_member(User.current)
        end
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_create)
			if @project.is_template?
			  redirect_to project_templates_path
            elsif params[:continue]
              attrs = {:parent_id => @project.parent_id}.reject {|k,v| v.nil?}
              redirect_to new_project_path(attrs)
            else
              redirect_to settings_project_path(@project)
            end
          }
          format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
        end
      else
        respond_to do |format|
          format.html { render :action => 'new' }
          format.api  { render_validation_errors(@project) }
        end
      end
    end
  
	def new_with_modification
	  @issue_custom_fields = IssueCustomField.sorted.to_a
      @trackers = Tracker.sorted.to_a
      @project = Project.new
      @project.safe_attributes = params[:project]
	  if @project.is_template?
	    p = ProjectTemplate.order('id DESC').first
		@project.set_identifier((p.nil? ? 'template001' : p.identifier.to_s.succ))
	  end
	end
	def index_with_modification
	  retrieve_query('p')
		
	  if params[:format] == 'csv'
			if params[:query_id]
				begin
					@query = ProjectQuery.find(params[:query_id])
				rescue
					@query = ProjectQuery.build_from_params(session[:query_project], :name => '_')
				end
			else
				@query = ProjectQuery.build_from_params(session[:query_project], :name => '_')
			end
		elsif @query.instance_of?(IssueQuery)
			@query = ProjectQuery.build_from_params(params, :name => '_')
			@query.filters = {"status"=>{:operator=>"=", :values=>["1"]}} if @query.filters == {}
			
		end
	  sort_init(@query.sort_criteria.empty? ? [['name']] : @query.sort_criteria)
	  sort_update(@query.sortable_columns)
	  @query.sort_criteria = sort_criteria.to_a
	  if @query.valid?
		case params[:format]
		  when 'csv', 'pdf', 'xlsx'
			@limit = Setting.issues_export_limit.to_i
		  when 'atom'
			@limit = Setting.feeds_limit.to_i
		  when 'xml', 'json'
			@offset, @limit = api_offset_and_limit
		  else
			@limit = per_page_option
		end
			
		if params[:query_id]
		  @query.add_extra_data
		end
			
		scope = Project
		closed = false
		unless params[:closed]
		  scope = scope.active
		  closed = true
		end
			
		@project_count = @query.count
		@project_pages = Redmine::Pagination::Paginator.new @project_count, per_page_option, params['page']
		@offset ||=  @project_pages.offset
			
		@projects = @query.projects(
		  :order => sort_clause,
		  :include => [],
		  :closed => closed,
		  :limit  =>  @limit,
		  :offset =>  @offset
		)
		respond_to do |format|
		  format.html {
			session[:query_project] = params
		  }
		  format.api  {
			@offset, @limit = api_offset_and_limit
			@project_count = Project.visible.count
			@projects = Project.visible.offset(@offset).limit(@limit).order('lft').all
		  }
		  format.atom {		
			projects = Project.visible.order('created_on DESC').limit(Setting.feeds_limit.to_i).all
			render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
		  }
		  format.csv  { 
			send_data(query_to_csv(@projects, @query, params), :type => 'text/csv; header=present', :filename => 'projects.csv') 
		  }
		 end
       end
     end
   end
end
