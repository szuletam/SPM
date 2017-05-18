module PlanningHelper
  def get_th_months(month_array, keys)
	th = ""
    keys.each do |k|
      next if ! @issues.any?
	  curr = k.split('-')
	  month = month_name(curr[1].to_i)
	  th += "<th colspan='#{month_array[k].size}' class='month'>#{curr[0]}-#{month}</th>"
	end
	th.html_safe
  end
	
  def get_th_days(month_array, keys)
	th = ""
    keys.each do |k|
      month_array[k].each do |day|
		next if ! @issues.any?
		th += "<th class='day'>#{day.day}<br/>#{day_name(day.wday)[0..2]}</th>"
	  end
	end
	th.html_safe
  end
  
  def daily_hours(issues, user, project, min_date, update_issues=false)
	member = @project.members.where(:user_id => user.id).first
	member.user_calendar = member.user_calendar.nil? ? UserCalendar.default : member.user_calendar
	return {:hours => {}, :max_date => Time.now.to_date + 30.day} if issues.any? == false || member.user_calendar.nil?
	hours = {}
	max_date = Time.now.to_date
	date_start = min_date 
	
	available = 0
	issues.each do |issue|
	  issue.update_attribute(:start_date, date_start) if update_issues
	  if available == 0
		available = get_available(date_start, member)
	  end
	  estimated = issue.estimated_hours.nil? ? 0 : issue.estimated_hours
	  if estimated > available
		while estimated > available
		  estimated = estimated - available
	      hours[date_start.strftime("%Y-%m-%d")] ||= {}
		  hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = available
		  date_start = date_start + 1.day
		  if Holiday.is_holiday?(date_start)
			hours[date_start.strftime("%Y-%m-%d")] ||= {}
			hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = 0.0
			date_start = date_start + 1.day 
		  end
		  available = get_available(date_start, member)
		end
		if estimated != 0
		  #siguiente dia
		  tmp_available = available
		  available = available - estimated
		  hours[date_start.strftime("%Y-%m-%d")] ||= {}
		  hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = estimated
		  date_start = date_start + 1.day if tmp_available == estimated
		  estimated = 0
		end
	  elsif estimated == available
		available = 0
		hours[date_start.strftime("%Y-%m-%d")] ||= {}
		hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = estimated
		date_start = date_start + 1.day
		if Holiday.is_holiday?(date_start)
		  hours[date_start.strftime("%Y-%m-%d")] ||= {}
		  hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = 0.0
		  date_start = date_start + 1.day 
		end
		estimated = 0
	  else
		available = available - estimated
		hours[date_start.strftime("%Y-%m-%d")] ||= {}
		hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = estimated
		date_start = date_start + 1.day if available == 0
		if Holiday.is_holiday?(date_start)
		  hours[date_start.strftime("%Y-%m-%d")] ||= {}
		  hours[date_start.strftime("%Y-%m-%d")][issue.id.to_s.to_sym] = 0.0
		  date_start = date_start + 1.day 
		end
		estimated = 0
	  end
	  issue.update_attribute(:due_date, date_start) if update_issues
	  max_date = date_start
	end 
	
	return {:hours => hours, :max_date => max_date}
  end
  
  def get_available(date_start, member)
	available = member.scheduled_by_day(member.user_calendar_id, date_start.cwday)
  end
  
  def get_td_data(month_array, keys, issue)
	th = ""
	keys.each do |k|
	  month_array[k].each do |day|
	    next if ! @issues.any?
	    content = "-"
	    is_selected = false
	    if ! @daily_hours_data[:hours][day.strftime("%Y-%m-%d")].nil?
	      if ! @daily_hours_data[:hours][day.strftime("%Y-%m-%d")][issue.id.to_s.to_sym].nil?
		    content = @daily_hours_data[:hours][day.strftime("%Y-%m-%d")][issue.id.to_s.to_sym].to_f
		    is_selected = true
		  end
	    end
	    th += "<td class='day' style='background-color: #{get_color_cell(day, is_selected)}'>#{content}</td>"
	  end
	end
	th.html_safe
  end
	
  def get_color_cell(date, is_selected)
	if is_selected
	  @colors[:pcr]
	elsif date.strftime("%Y-%m-%d") == Time.now.to_date.strftime("%Y-%m-%d")
	  @colors[:current_day]
	elsif @holidays.include?(date)
	  @colors[:holiday_color]
	elsif Setting.non_working_week_days.include?(date.cwday.to_s)
	  @colors[:end_of_week]
	else 
	  ""
	end
  end
  
end
