class HolidaysController < ApplicationController
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include ContextMenusHelper
  helper :context_menus
  include HolidaysHelper
    
  before_filter :require_admin
  
  before_filter :find_holiday, :except => [:index]
  
  def index
	retrieve_query
	if params[:format] == 'csv'
		if params[:query_id]
			begin
				@query = HolidayQuery.find(params[:query_id])
			rescue
				@query = HolidayQuery.build_from_params(session[:query_holiday], :name => '_')
			end
		else
			@query = HolidayQuery.build_from_params(session[:query_holiday], :name => '_')
		end
	elsif @query.instance_of?(IssueQuery)
		@query = HolidayQuery.build_from_params(params, :name => '_')
	end
	sort_init(@query.sort_criteria.empty? ? [['date']] : @query.sort_criteria)
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
	
	
	@holiday_count = @query.count
	@holiday_pages = Redmine::Pagination::Paginator.new @holiday_count, per_page_option, params['page']
	@offset ||=  @holiday_pages.offset
	
	@holidays = @query.holidays(
	  :order => sort_clause,
	  :include => [],
	  :limit  =>  @limit,
	  :offset =>  @offset
	)
		
	respond_to do |format|
	  format.html {
		session[:query_holiday] = params
	  }
	  
	  format.csv  { 
	    send_data(query_to_csv(@holidays, @query, params), :type => 'text/csv; header=present', :filename => 'holidays.csv') 
	  }
	  end
    end
  end

  def edit
  end

  def update
	@holiday.safe_attributes = params[:holiday].permit(:date, :description)
    if @holiday.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
		  redirect_to holidays_path
        }
      end
    else
      respond_to do |format|
        format.html { render :action => :edit }
      end
    end
  end

  def create
	@holiday.safe_attributes = params[:holiday].permit(:date, :description)
    if @holiday.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to holidays_path
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
    @holiday.destroy
    respond_to do |format|
      format.html { 
		flash[:notice] = l(:notice_successful_delete)
		redirect_back_or_default(holidays_path) 
	  }
    end
  end
  
  private 
  
  def find_holiday
	begin
		@holiday = Holiday.find(params[:id])
	rescue
		@holiday = Holiday.new
	end
  end
end
