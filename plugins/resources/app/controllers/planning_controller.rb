class PlanningController < ApplicationController
  before_filter :find_project, :colors
  
  include PlanningHelper
  
  helper :planning
  
  menu_item :issues
  
  def simulate
	@users = @project.principals
	@issues = []
	@keys = []
	@month_hash	= {}
	if request.post?
	  @min_date = Time.now
	  @max_date = Time.now
	  @update_issue_dates = (params[:update_issue_dates].to_i == 1 ? true : false) if params[:update_issue_dates]
	  if params[:user_id] && ! params[:user_id].empty?
		@user = User.find(params[:user_id])
		@issues = @project.issues.visible.open.where(["assigned_to_id = ?", @user.id]).order("subject")
		@min_date = @project.issues.visible.open.where(["assigned_to_id = ?", @user.id]).order("start_date, subject").minimum(:start_date)
		@min_date = Time.now.to_date if @min_date.nil? 
		@min_date = params[:start_date].to_date if params[:start_date] && ! params[:start_date].empty?  rescue Time.now.to_date
	  end
	  
	  @daily_hours_data = daily_hours(@issues, @user, @project, @min_date, (@update_issue_dates.nil? ? false : @update_issue_dates))
	  @max_date = @daily_hours_data[:max_date]
	  tmp_min_date = @min_date 
	  while tmp_min_date <= @max_date
		@month_hash["#{tmp_min_date.year}-#{(tmp_min_date.month < 10 ? "0#{tmp_min_date.month}" : tmp_min_date.month)}"] ||= []
		@month_hash["#{tmp_min_date.year}-#{(tmp_min_date.month < 10 ? "0#{tmp_min_date.month}" : tmp_min_date.month)}"] << tmp_min_date
		tmp_min_date = tmp_min_date + 1.day
	  end
	  
	  @keys = @month_hash.keys.sort
	  @holidays = Holiday.between(@min_date , @max_date).map{|holiday| holiday.date}
    end
  end
  
  def colors
    @colors = {
	  :current_day => "#FFDAB9",
	  :end_of_week => "#DFF2BF", 
	  :project_color => " #C3C3C3", 
	  :total_color => "#AAAAFF", 
	  :holiday_color => "#FEEFB3", 
	  :pcr => "#CCCCFF"
	}
  end
end
