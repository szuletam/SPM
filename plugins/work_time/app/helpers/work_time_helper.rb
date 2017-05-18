module WorkTimeHelper
  def work_time_issue_link(issue)
    title = nil
    subject = nil
    text = "#{@trackers[issue.tracker_id]} ##{issue.id}"
		title = issue.subject.truncate(60)
    subject = issue.subject
	
    s = link_to(text, issue_url(issue),
                :class => issue.css_classes, :title => title)
    s << h(": #{subject}") if subject
    s
  end
  
  def csv_report
    cols = [l(:label_day_plural).capitalize] + render_days_csv
	
		Redmine::Export::CSV.generate do |csv|
      # csv header fields
      csv << cols
      
	  	@issues.each do |issue|
	    	unless @draw_projects.include?(issue.project_id)
					cols = [
					(@projects[issue.project_id] ? @projects[issue.project_id] : "")
					] + render_project_hours_csv(@projects[issue.project_id] ?  @projects[issue.project_id] : nil)

					@draw_projects << issue.project_id
				end
		
				cols = [
					issue.subject
				] + render_hours_csv(issue)
				csv << cols
			end
	  
	  csv << render_total_hours_csv
    end
	
  end
  
  def render_days_csv
		ths = []
		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			ths << date.day.to_s + " - " + day_short(date.cwday)
		end
		ths << l(:label_total)
		ths
  end
  
  def css_help
    colors = {
	  :holiday => "holiday-cell",
	  :non_working => "non-working-cell",
	  :today => "today-cell"
		}
		content_holiday = content_tag(:span, '&nbsp;&nbsp;&nbsp;'.html_safe,
																	:class => "#{colors[:holiday]}", :style => "border: #000 solid 1px;") + " #{l(:label_holiday_help)} "
		content_non_working = content_tag(:span, '&nbsp;&nbsp;&nbsp;'.html_safe,
																	:class => "#{colors[:non_working]}", :style => "border: #000 solid 1px;") + " #{l(:label_non_working_help)} "
		content_today = content_tag(:span, '&nbsp;&nbsp;&nbsp;'.html_safe,
																	:class => "#{colors[:today]}", :style => "border: #000 solid 1px;") + " #{l(:label_today_help)} "
    return content_holiday + content_non_working + content_today
  end
  
  def css_for_cell(date, issue =nil)
		colors = {
			:holiday => "holiday-cell",
			:non_working => "non-working-cell",
			:today => "today-cell",
			:not_leaf => "not-leaf-cell"
		}
		return colors[:not_leaf] if issue  && !issue.leaf?
		return colors[:today] if date == Date.today
		return colors[:non_working] if Setting.non_working_week_days.include?(date.cwday.to_s)
		return colors[:holiday] if @holidays.include?(date)
  end
  
  def render_issue_select
		select_tag "selected_issue_id",
		options_from_collection_for_select([], "id", "name", params[:issue_id]), 
		:id => :selected_issue_id, 
		:style => "width:100%; display: none;", 
		:include_blank => true,
		:onchange => "include_issue('#{work_time_include_issue_path}', '#{@date.strftime("%Y-%m-%d")}', '#{@user.id}', '#{(@project.nil? ? '' : @project.id)}')"
  end
  
  def render_project_select
		select_tag "selected_project_id",
		options_from_collection_for_select(@user_projects, "id", "name", params[:project_id]),
		:id => :selected_project_id,
		:style => "width:100%;",
		:include_blank => true,
		:onchange => "load_issues('#{work_time_load_issues_path}', '#{@date.strftime("%Y-%m-%d")}', '#{@user.id}')"
  end
  
  def render_total_hours_csv
    tds = []
		tds << l(:label_total)
		totals = {}
		total = 0
		@time_entries.each do |k, v|
			totals[k[0]] = 0 if totals[k[0]].nil?
			totals[k[0]] += v.round(2)
		end

		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			td = ""
			unless totals[date].nil?
				td = totals[date].round(2).to_s
			total += totals[date].round(2)
			else
				td = 0
			end
			tds << td
		end
	 
		tds << total

		tds
  end
  
  def render_total_hours_tr
    tds = ""
		tds << content_tag('td',
			"#{render_project_select}<br/> #{render_issue_select}".html_safe
		)
		totals = {}
		total = 0
		@time_entries.each do |k, v|
			totals[k[0]] = 0 if totals[k[0]].nil?
			totals[k[0]] += v.round(2)
		end

		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			td = ""
			unless totals[date].nil?
				td << content_tag("td", content_tag("span", totals[date].round(2)), :class => "td-total-day #{css_for_cell(date)}")
			total += totals[date].round(2)
			else
				td << content_tag("td", content_tag("span", 0), :class => "td-total-day #{css_for_cell(date)}")
			end
			tds << td
		end
		tds << content_tag("td", content_tag("span", "#{total}"), :class => "td-total-day")
		tds.html_safe
  end
  
  def render_remove_work_time(issue)
		(link_to_function image_tag('delete.png'), "remove_issue('#{work_time_remove_issue_path}', #{issue}, '#{@date.strftime("%Y-%m-%d")}', #{@user.id}, #{(@project.nil? ? 0 : @project.id)}, '#{l(:text_are_you_sure)}')").html_safe
  end
  
  def render_project_hours_csv(project)
		tds = []
		total = 0
		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			td = ""
			unless @project_time_entries[[date, project.id]].nil?
				total += @project_time_entries[[date, project.id]].to_f.round(2)
				td << @project_time_entries[[date, project.id]].round(2).to_s
			else
				td << 0
			end
			tds << td
		end
		tds << total
		tds
  end
  
  def render_project_hours_td(project)
		tds = ""
		total = 0
		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			td = ""
			unless @project_time_entries[[date, project.id]].nil?
				total += @project_time_entries[[date, project.id]].to_f.round(2)
				td << content_tag("td", @project_time_entries[[date, project.id]].round(2), :class => "td-project", :style => "text-decoration: underline;")
			else
				td << content_tag("td", 0, :class => "td-project")
			end

			tds << td
		end
		tds << content_tag("td", "#{total}", :class => "td-total-project td-project")
		tds.html_safe
  end
  
  def render_hours_td(issue)
    tds = ""
		total = 0

		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			td = ""
			unless @time_entries[[date, issue.id]].nil?
				total += @time_entries[[date, issue.id]].to_f.round(2)
			td << content_tag("td", @time_entries[[date, issue.id]].round(2),
			:class => "td-day td-active #{css_for_cell(date,issue)}",
			"data-empty".to_sym => false,
			"data-issue".to_sym => issue.id,
			"data-date".to_sym => date.strftime("%Y-%m-%d"),
			"data-user".to_sym => @user.id,
			"data-project".to_sym => (! @project.nil? ? 1 : 0),
			"data-leaf".to_sym => ( issue.leaf? ? 1 : 0),
			"data-url".to_sym => work_time_edit_path)
			else
				td << content_tag("td", "", :class => "td-day #{css_for_cell(date,issue)}",
			"data-empty".to_sym => true,
			"data-issue".to_sym => issue.id,
			"data-date".to_sym => date.strftime("%Y-%m-%d"),
			"data-user".to_sym => @user.id,
			"data-project".to_sym => (! @project.nil? ? 1 : 0),
			"data-leaf".to_sym => ( issue.leaf? ? 1 : 0),
			"data-url".to_sym => work_time_new_path)
			end
			tds << td
		end
		tds << content_tag("td", "#{total}", :class => "td-total-issue")
		tds.html_safe
  end
  
  def render_hours_csv(issue)
    tds = []
		total = 0
		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			td = ""
			unless @time_entries[[date, issue.id]].nil?
				total += @time_entries[[date, issue.id]].to_f.round(2)
			td << @time_entries[[date, issue.id]].round(2).to_s
			else
				td << ""
			end
			tds << td
		end
		tds << total
		tds
  end
  
  def render_days_th
		ths = ""
		@date.beginning_of_month.upto(@date.end_of_month) do |date|
			ths << content_tag('th', content_tag("div", date.day, :style => "font-weight: bold;") + content_tag("div", day_short(date.cwday), :style => "font-weight: bold;"), :class => "th-day")
		end
		ths << content_tag('th', "&nbsp;".html_safe, :class => "th-option")
		ths.html_safe
  end
  
  def render_month_th
		th = ""
			th << content_tag('tr',
			content_tag('th',
			render_previus_month_link.html_safe + month_name(@date.month) + " - #{@date.year}" + render_next_month_link.html_safe, :class => "th-month", :colspan => (2 + @date.end_of_month.day.to_i), :valign => "middle")
		)
		th.html_safe
  end
  
  def render_next_month_link
		"&nbsp;&nbsp;".html_safe + link_to(image_tag('right-arrow.png', :plugin => :work_time), work_time_path(params.merge(:date => @date.next_month).merge(:controller => :work_time).merge(:action => :index))).html_safe
  end
  
  def render_previus_month_link
		link_to(image_tag('left-arrow.png', :plugin => :work_time), work_time_path(params.merge(:date => @date.prev_month).merge(:controller => :work_time).merge(:action => :index))).html_safe + "&nbsp;&nbsp;".html_safe
  end
  
  def day_short(day)
    ::I18n.t('date.abbr_day_names')[day % 7].at(0..2)
  end
end
