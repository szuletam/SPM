class UserCalendarsController < ApplicationController
  
  before_filter :require_admin
  
  before_filter :find_user_calendar
  
  helper 'sort'
  
  include SortHelper
  
  layout "admin"
  
  def index
    sort_init 'name', 'asc'
    sort_update %w(name created_on)

    @limit = per_page_option

    scope = UserCalendar.where(nil)
    scope = scope.where("name LIKE '%#{params[:name]}%'") if params[:name].present?

    @user_calendar_count = scope.count
    @user_calendar_pages = Paginator.new @user_calendar_count, @limit, params['page']
    @offset ||= @user_calendar_pages.offset
    @user_calendars =  scope.order(sort_clause).limit(@limit).offset(@offset).to_a

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
    end
  end
  
  def create
	@user_calendar.safe_attributes = params[:user_calendar].permit(:name)
	
	make_days_ranges(params[:calendar_hours]).each do |k, v|
	  @user_calendar.user_calendar_hours << UserCalendarHour.new(
		:init => v.min,
		:due => v.max,
		:total_hours => v.max - v.min, 
		:week_day => k
	  )
	end
	
    if @user_calendar.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to user_calendars_path
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end
  
  def edit
    @user_calendar_hours = hours_for_edit(@user_calendar.user_calendar_hours)
  end
  
  def get_calendar_table
	@user_calendar = UserCalendar.default if @user_calendar.new_record?
    @user_calendar_hours = hours_for_edit(@user_calendar.user_calendar_hours)
  end
  
  def hours_for_edit(hours)
	days = {}
	hours.each do |hour|
	  days[hour.week_day] ||= []
	  (hour.init..hour.due).each do |h|
	    days[hour.week_day] << h.to_i
	  end
	end
	days
  end
  
  def new
  end
  
  def update
	@user_calendar.safe_attributes = params[:user_calendar].permit(:name)
	@user_calendar.user_calendar_hours.destroy_all
	make_days_ranges(params[:calendar_hours]).each do |k, v|
	  @user_calendar.user_calendar_hours << UserCalendarHour.new(
		:init => v.min,
		:due => v.max,
		:total_hours => v.max - v.min, 
		:week_day => k
	  )
	end
	
    if @user_calendar.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
		  redirect_to user_calendars_path
        }
      end
    else
      respond_to do |format|
        format.html { render :action => :edit }
      end
    end
  end
  
  def destroy
    @user_calendar.destroy
    respond_to do |format|
      format.html { 
		flash[:notice] = l(:notice_successful_delete)
		redirect_back_or_default(user_calendars_path) 
	  }
    end
  end
  
  private 
  
  def find_user_calendar
	begin
		@user_calendar = UserCalendar.find(params[:id])
	rescue
		@user_calendar = UserCalendar.new
	end
  end
  
  def make_days_ranges(days)
	week_days = []
	Rack::Utils.parse_nested_query(days).each do |k, v|
	  next if v.empty?
	  element = 0
	  tmp = []
	  elements = v.split(',')
	  elements.each do |h|
		tmp << h.to_i 
		unless elements.include?((h.to_i + 1).to_s)
		  week_days << [k, tmp]
		  tmp = [] 
		end
	  end
	end
	week_days
  end
  
end
