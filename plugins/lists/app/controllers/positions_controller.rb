class PositionsController < ApplicationController
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include ContextMenusHelper
  helper :context_menus
  include PositionsHelper
    
  before_filter :require_admin
  
  before_filter :find_position, :except => [:index]
  
  def index
		retrieve_query
		if params[:format] == 'csv'
			if params[:query_id]
				begin
					@query = PositionQuery.find(params[:query_id])
				rescue
					@query = PositionQuery.build_from_params(session[:query_position], :name => '_')
				end
			else
				@query = PositionQuery.build_from_params(session[:query_position], :name => '_')
			end
		elsif @query.instance_of?(IssueQuery)
			@query = PositionQuery.build_from_params(params, :name => '_')
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
		
		
		@position_count = @query.count
		@position_pages = Redmine::Pagination::Paginator.new @position_count, per_page_option, params['page']
		@offset ||=  @position_pages.offset
		
		@positions = @query.positions(
			:order => sort_clause,
			:include => [],
			:limit  =>  @limit,
			:offset =>  @offset
		)
			
		respond_to do |format|
			format.html {
				session[:query_position] = params
			}
			
			format.csv  { 
				send_data(query_to_csv(@positions, @query, params), :type => 'text/csv; header=present', :filename => 'positions.csv')
			}
			end
    end
  end

  def edit
  end

  def update
	@position.safe_attributes = params[:position].permit(:name, :initial)
	if @position.save
		respond_to do |format|
			format.html {
				flash[:notice] = l(:notice_successful_update)
				redirect_to positions_path
			}
		end
	else
		respond_to do |format|
			format.html { render :action => :edit }
		end
	end
  end

  def create
		@position.safe_attributes = params[:position].permit(:name, :initial)
    if @position.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to positions_path
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
		if @position.user.nil?
			@position.destroy
		end
    respond_to do |format|
      format.html { 
				flash[:notice] = l(:notice_successful_delete)
				redirect_back_or_default(positions_path)
			}
    end
  end
  
  private 
  
  def find_position
		begin
			@position = Position.find(params[:id])
		rescue
			@position = Position.new
		end
  end
end
