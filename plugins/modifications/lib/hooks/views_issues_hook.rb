class ViewsIssuesHook < Redmine::Hook::ViewListener
  require 'uri'
  require 'cgi'
  
  render_on :view_issues_show_description_bottom, :partial => "issues/checklist"
  render_on :view_issues_form_details_bottom, :partial => "issues/recurrent_issues"
  render_on :view_issues_form_details_bottom, :partial => "issues/checklist_form"
  
  
  def controller_issues_new_after_save(context={ })	
	if ! context[:params][:recurrent_issue].nil?
	  dates = Array.new
	  url_data = CGI::parse(context[:params][:form_recurrence_data])
	  case url_data["recurrence_type"][0]
		when 'daily'
		  date_start = url_data["recurrence_beginning"][0].to_date
		  step = url_data["recurrence_days"][0].to_i
		  if url_data["recurrence_ending_type"][0] == 'recurrence_ending'
			iterations = url_data["recurrence_ending"][0].to_i
			valid = true
			date_end = date_start
			while(valid)
			  # validar que no puede crear una repeticion cada 7 dias, siendo no laboral si elije un sabado o un domingo como fecha de inicio
			  if url_data["recurrence_days_type"][0] == 'all_days'
				dates << date_end
				date_end = date_end + step.day
			  elsif url_data["recurrence_days_type"][0] == 'work_days'
				if ! [0, 6].include? date_end.wday
				  dates << date_end
				  date_end = date_end + step.day
				else
				  while([0, 6].include? date_end.wday)
				    date_end = date_end + 1.day
				  end
				  dates << date_end
				  date_end = date_end + step.day
				end
			  end
			  iterations = iterations - 1
			  if iterations <= 0
				valid = false
			  end
			end
		  elsif url_data["recurrence_ending_type"][0] == 'recurrence_end_after'
			date_end = url_data["recurrence_end_after"][0].to_date
			i = 0
			while(date_start <= date_end)
			  if url_data["recurrence_days_type"][0] == 'all_days'
				dates << date_start
				date_start = date_start + step.day
			  elsif url_data["recurrence_days_type"][0] == 'work_days'
				if ! [0, 6].include? date_start.wday
				  dates << date_start
				  date_start = date_start + step.day
				else
				  while([0, 6].include? date_start.wday)
					date_start = date_start + 1.day
				  end
				  dates << date_start
				  date_start = date_start + step.day
				end
			  end
		      if date_start + step.day > date_end
			    break
			  end	
		    end
		  end
		when 'weekly'
		  wdays_selected = url_data["recurrence_days_of_week"]
		  date_start = url_data["recurrence_beginning"][0].to_date
          if url_data["recurrence_ending_type"][0] == 'recurrence_ending'
			iterations = url_data["recurrence_ending"][0].to_i
			valid = true
			date_start_tmp = date_start.to_datetime.beginning_of_week
			date_end = date_start_tmp + (iterations.to_i * 7).day
			while(date_start <= date_end)
			  # validar que no puede crear una repeticion cada 7 dias, siendo no laboral si elije un sabado o un domingo como fecha de inicio
			  if is_week_day(date_start,wdays_selected) 
				dates << date_start.to_date
			  end
			  date_start = date_start + 1.day;
			end
		  elsif url_data["recurrence_ending_type"][0] == 'recurrence_end_after'
			date_end = url_data["recurrence_end_after"][0].to_date
			while(date_start <= date_end)
			  # validar que no puede crear una repeticion cada 7 dias, siendo no laboral si elije un sabado o un domingo como fecha de inicio
			  if is_week_day(date_start,wdays_selected) 
				dates << date_start.to_date
			  end
			  date_start = date_start + 1.day;
			end
		  end
		when 'monthly'
		  date_start = url_data["recurrence_beginning"][0].to_date
		  step = url_data["recurrence_of_every_monthly"][0].to_i
		  day = url_data["recurrence_day_monthly"][0].to_i 
		  if url_data["recurrence_ending_type"][0] == 'recurrence_ending'
			iterations = url_data["recurrence_ending"][0].to_i
			valid = true
			tmp_date = "#{date_start.year}-#{date_start.month}-#{day}"
			tmp_date = normalize(tmp_date, date_start, day) if !is_date?(tmp_date)
			date_start = tmp_date.to_date
			while(valid)
			  dates << date_start
			  date_start = date_start + step.month
			  iterations = iterations - 1
			  tmp_date = "#{date_start.year}-#{date_start.month}-#{day}"
			  tmp_date = normalize(tmp_date, date_start, day) if !is_date?(tmp_date)
			  date_start = tmp_date.to_date
			  if iterations <= 0
				valid = false
			  end
			end
		  elsif url_data["recurrence_ending_type"][0] == 'recurrence_end_after'
			date_end = url_data["recurrence_end_after"][0].to_date
			tmp_date = "#{date_start.year}-#{date_start.month}-#{day}"
			tmp_date = normalize(tmp_date, date_start, day) if !is_date?(tmp_date)
			date_start = tmp_date.to_date
			while(date_start <= date_end)
			  dates << date_start
			  date_start = date_start + step.month
			  tmp_date = "#{date_start.year}-#{date_start.month}-#{day}"
			  tmp_date = normalize(tmp_date, date_start, day) if !is_date?(tmp_date)
			  date_start = tmp_date.to_date
			end
		  end
		when 'yearly'
		  date_start = url_data["recurrence_beginning"][0].to_date
		  if url_data["recurrence_ending_type"][0] == 'recurrence_ending'
			iterations = url_data["recurrence_ending"][0].to_i
			valid = true
			date_end = date_start
		  while(valid)
			dates << date_start
			date_start = date_start +  1.year
			iterations = iterations - 1
			if iterations <= 0
			  valid = false
			end
		  end
		elsif url_data["recurrence_ending_type"][0] == 'recurrence_end_after'
		  date_end = url_data["recurrence_end_after"][0].to_date
		  while(date_start < date_end)
			dates << date_start
			date_start = date_start +  1.year
		  end
		end
	  else
	  end
	  dates.each do |date|
		new_issue = Issue.new
		context[:issue].attributes.each do |key, value|
		  next if ["rgt", "lft", "created_on", "updated_on", "id"].include?(key)
		  new_issue[key] = value
		end	
			
		new_issue.start_date = date.to_date
		new_issue.due_date = date.to_date
		new_issue.parent_id = context[:issue].id
		new_issue.subject = "#{new_issue.subject}"
		new_issue.recurrent = true
		new_issue.save	
	  end
	else	
	end
  end
	
  def is_week_day(date_start,wdays_selected)
	if wdays_selected.include? date_start.strftime("%A").downcase
	  true
	else
	  false
	end
  end
	
  def is_date?(text)
	begin
	  return true if text.to_date
	rescue;end
    return false
  end
	
  def normalize(tmp_date, date_start, day)
	while !is_date?(tmp_date)
	  tmp_date = "#{date_start.year}-#{date_start.month}-#{(day.to_i - 1)}"
    end
    tmp_date
  end
	
  
end
