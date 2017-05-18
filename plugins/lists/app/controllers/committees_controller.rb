class CommitteesController < ApplicationController
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include ContextMenusHelper
  helper :context_menus
  include CommitteesHelper
    
  before_filter :require_admin
  
  before_filter :find_committee, :except => [:index]
  
  def index
		retrieve_query
		if params[:format] == 'csv'
			if params[:query_id]
				begin
					@query = CommitteeQuery.find(params[:query_id])
				rescue
					@query = CommitteeQuery.build_from_params(session[:query_committee], :name => '_')
				end
			else
				@query = CommitteeQuery.build_from_params(session[:query_committee], :name => '_')
			end
		elsif @query.instance_of?(IssueQuery)
			@query = CommitteeQuery.build_from_params(params, :name => '_')
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
		
		
		@committee_count = @query.count
		@committee_pages = Redmine::Pagination::Paginator.new @committee_count, per_page_option, params['page']
		@offset ||=  @committee_pages.offset
		
		@committees = @query.committees(
			:order => sort_clause,
			:include => [],
			:limit  =>  @limit,
			:offset =>  @offset
		)
			
		respond_to do |format|
			format.html {
				session[:query_committee] = params
			}
			
			format.csv  { 
				send_data(query_to_csv(@committees, @query, params), :type => 'text/csv; header=present', :filename => 'committees.csv') 
			}
			end
    end
  end

  def edit
  end

  def update
	@committee.safe_attributes = params[:committee].permit(:name, :periodicity, :initial, :objectives, :kpi, :deliverable)
	if @committee.save
		respond_to do |format|
			format.html {
				flash[:notice] = l(:notice_successful_update)
				redirect_to committees_path
			}
		end
	else
		respond_to do |format|
			format.html { render :action => :edit }
		end
	end
  end

  def create
		@committee.safe_attributes = params[:committee].permit(:name, :periodicity, :initial, :objectives, :kpi, :deliverable)
    if @committee.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to committees_path
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
    @committee.destroy
    respond_to do |format|
      format.html { 
				flash[:notice] = l(:notice_successful_delete)
				redirect_back_or_default(committees_path) 
			}
    end
  end
  
  private 
  
  def find_committee
		begin
			@committee = Committee.find(params[:id])
		rescue
			@committee = Committee.new
		end
  end
end
