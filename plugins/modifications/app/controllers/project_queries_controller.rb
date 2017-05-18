class ProjectQueriesController < ApplicationController
  menu_item :issues
  before_filter :find_query, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create]

  accept_api_auth :index

  include QueriesHelper
  helper :queries
  
  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @query_count = ProjectQuery.visible.count
    @query_pages = Paginator.new @query_count, @limit, params['page']
    @queries = ProjectQuery.visible.all(:limit => @limit, :offset => @offset, :order => "#{Query.table_name}.name")

    respond_to do |format|
      format.api
    end
  end

  def new
    @query = ProjectQuery.new
    @query.user = User.current
    @query.project = @project
    @query.build_from_params(params)
  end

  def create
    @query = ProjectQuery.new(params[:query])
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :query_id => @query, :controller => :projects
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.attributes = params[:query]
    @query.project = nil if params[:query_is_for_all]
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :query_id => @query, :controller => :projects
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
	redirect_to :set_filter => 1, :controller => :projects 
  end

private
  def find_query
    @query = ProjectQuery.find(params[:id])
    @project = @query.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
