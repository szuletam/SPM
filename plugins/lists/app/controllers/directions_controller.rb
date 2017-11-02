class DirectionsController < ApplicationController
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include ContextMenusHelper
  helper :context_menus
  include DirectionsHelper
    
  before_filter :require_admin
  
  before_filter :find_direction, :except => [:index]
  
  def index
		retrieve_query
		if params[:format] == 'csv'
			if params[:query_id]
				begin
					@query = DirectionQuery.find(params[:query_id])
				rescue
					@query = DirectionQuery.build_from_params(session[:query_direction], :name => '_')
				end
			else
				@query = DirectionQuery.build_from_params(session[:query_direction], :name => '_')
			end
		elsif @query.instance_of?(IssueQuery)
			@query = DirectionQuery.build_from_params(params, :name => '_')
		end
		sort_init(@query.sort_criteria.empty? ? [['name']] : @query.sort_criteria)
		sort_update(@query.sortable_columns)
		@query.sort_criteria = sort_criteria.to_a
		
		if @query.valid?
			case params[:format]
			when 'csv', 'pdf'
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
		
		
		@direction_count = @query.count
		@direction_pages = Redmine::Pagination::Paginator.new @direction_count, per_page_option, params['page']
		@offset ||=  @direction_pages.offset
		
		@directions = @query.directions(
			:order => sort_clause,
			:include => [],
			:limit  =>  @limit,
			:offset =>  @offset
		)
			
		respond_to do |format|
			format.html {
				session[:query_direction] = params
			}
			
			format.csv  { 
				send_data(query_to_csv(@directions, @query, params), :type => 'text/csv; header=present', :filename => 'directions.csv') 
			}
			end
    end
  end

  def edit
  end

  def update
	@direction.safe_attributes = params[:direction].permit(:name, :initial, :equivalent)
	if @direction.save
		respond_to do |format|
			format.html {
				flash[:notice] = l(:notice_successful_update)
				redirect_to directions_path
			}
		end
	else
		respond_to do |format|
			format.html { render :action => :edit }
		end
	end
  end

  def create
		@direction.safe_attributes = params[:direction].permit(:name, :initial)
    if @direction.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to directions_path
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def new
  end
  
  def destroy
    @direction.destroy
    respond_to do |format|
      format.html { 
				flash[:notice] = l(:notice_successful_delete)
				redirect_back_or_default(directions_path) 
			}
    end
  end
  
  private 
  
  def find_direction
		begin
			@direction = Direction.find(params[:id])
		rescue
			@direction = Direction.new
		end
  end
end
