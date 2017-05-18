module UserCalendarsHelper
  def calendar_header()
	day_start_of_week = Date.today.beginning_of_week
	day_end_of_week = Date.today.end_of_week
	ths = [content_tag("th","")]
	day_start_of_week.upto(day_end_of_week) do |date|
	  ths << content_tag("th", day_name(date.wday).at(0..2), :class => "")
	end
	content_tag("tr",ths.join("").html_safe)
  end
  
  def calendar_body(hours={})
	trs = []
	day_start_of_week = Date.today.beginning_of_week
	day_end_of_week = Date.today.end_of_week
	
	start_time = Setting.start_calendar_time.to_i
	start_time -= 1 unless start_time == 0
	
	ending_time = Setting.end_calendar_time.to_i
	ending_time += 1 unless ending_time == 24 

	(start_time..ending_time).each do |hour|
	  tds = []
	  tds << content_tag("td", "#{hour}:00", 
						:style=>"padding: 0px; margin:0px; font-size: 10px;")
	  day_start_of_week.upto(day_end_of_week) do |date|
	    tds << content_tag("td", "", :data => {:hour => "#{hour}", :day => date.cwday}, 
			:style=>"padding: 0px; margin:0px; font-size: 10px;", 
			:class => "tr-selectable day-#{date.cwday} #{class_selectable(hour, date.cwday, hours)}")
      end
	  trs << content_tag("tr", tds.join.html_safe, :class => cycle("odd", "even"))
	end
	trs.join.html_safe
  end

  def calendar_body_members(hours={})
	trs = []
	day_start_of_week = Date.today.beginning_of_week
	day_end_of_week = Date.today.end_of_week

	min = 24
	max = 0

	hours.each do |day, hours|
		min = hours.min
		max = hours.max
	end 

	min -= 1 unless min <= Setting.start_calendar_time.to_i
	max += 1 unless max >= Setting.end_calendar_time.to_i

	(min..max).each do |hour|
	  tds = []
	  tds << content_tag("td", "#{hour}:00", 
						:style=>"padding: 0px; margin:0px; font-size: 10px;")
	  day_start_of_week.upto(day_end_of_week) do |date|
	    tds << content_tag("td", "", :data => {:hour => "#{hour}", :day => date.cwday}, 
			:style=>"padding: 0px; margin:0px; font-size: 10px;", 
			:class => "tr-selectable day-#{date.cwday} #{class_selectable(hour, date.cwday, hours)}")
      end
	  trs << content_tag("tr", tds.join.html_safe, :class => cycle("odd", "even"))
	end
	trs.join.html_safe
  end
  
  def calendar_widget(hours={})
	content_tag("table", calendar_header + calendar_body(hours), :class => "list user-calendar-table")
  end

  def calendar_widget_members(hours={})
	content_tag("table", calendar_header + calendar_body_members(hours), :class => "list user-calendar-table")
  end
  
  def draw_hours(calendar)
	html = []
    calendar.user_calendar_hours.each do |cal|
	  html << day_name(cal.week_day) + " #{text_hour(cal.init)}:00 - #{text_hour(cal.due)}:00"
	end
	html.join(', ').html_safe
  end
  
  def text_hour(hour)
    hours = [
		1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
	]
	hours[hour.to_i]
  end
  
  def class_selectable(hour, day, hours)
	if ! hours[day.to_i]
	  return ""
	elsif ! hours[day.to_i].include?(hour)
	  return ""
	else
	  return "ui-selected"
	end
  rescue
	return ""
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
end
