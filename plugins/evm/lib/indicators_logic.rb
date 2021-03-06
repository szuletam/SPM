module IndicatorsLogic

  def self.real_start_and_end_date(project_or_version, time_entries_by_week_and_year, issues)
    end_date = project_or_version.due_date || Time.now.to_date
    begin
	  time_entry_max_date =
      time_entries_by_week_and_year.empty? ? Time.now.to_date :
        Date.ordinal(time_entries_by_week_and_year.keys.last[1],
                       time_entries_by_week_and_year.keys.last[0] * 7 - 3)
	rescue
	  time_entry_max_date = Date.today
	end
    if issues.maximum(:start_date)
      issue_max_start_date = issues.empty? ? Time.now.to_date : issues.maximum(:start_date)
      real_end_date =
          [end_date, time_entry_max_date, issue_max_start_date].max
    else
      real_end_date = [end_date, time_entry_max_date].max
    end
	begin
    real_start_date = [
          (project_or_version.start_date.nil? ?
            (Time.now.to_date - 1.day) :
              project_or_version.start_date.beginning_of_week),
          (time_entries_by_week_and_year.empty? || ()? 
            Time.now.to_date :
            ( time_entries_by_week_and_year.keys.first[1].nil? || (time_entries_by_week_and_year.keys.first[0] * 7 - 3).nil? ? Time.now.to_date : 
				Date.ordinal(time_entries_by_week_and_year.keys.first[1],
                           time_entries_by_week_and_year.keys.first[0] * 7 - 3)))
        ].min
	
	rescue 
		
	end
    return real_start_date, real_end_date
  end

  def self.calc_indicators(project_or_version)
    time_entries_by_week_and_year, issues = retrive_data(project_or_version)
    real_start_date, real_end_date =
      real_start_and_end_date(project_or_version, time_entries_by_week_and_year, issues)
    ary_weeks_years = []
	return [0, 0, 0] if real_start_date.nil? || real_end_date.nil?
    while real_start_date < real_end_date + 1.week
      ary_weeks_years << [real_start_date.cweek, real_start_date.cwyear]
      real_start_date += 1.week
    end
    hash_weeks_years = {}
    ary_weeks_years.each do |e|
      hash_weeks_years[e] = {}
      hash_weeks_years[e][:sum_planned] = 0
      hash_weeks_years[e][:sum_earned]  = 0
    end
    issues.each do |issue|
      next if !issue.leaf?
      start_issue_date = issue.start_date? ? issue.start_date : project_or_version.start_date
      end_issue_date = issue.due_date? ? issue.due_date : real_end_date
      estimated_time = issue.estimated_hours? ? issue.estimated_hours : 0
      done_ratio = (issue.done_ratio / 100.0)
      if (not start_issue_date.nil?) && (not end_issue_date.nil?)
        ary_dates = (start_issue_date..end_issue_date).to_a
        ary_dates.delete_if{|x| x.cwday == 6 || x.cwday == 7}
        if ary_dates.any? && estimated_time != 0
          hoursPerDay = estimated_time / ary_dates.size
          ary_dates.each do |day|
            week = day.cweek
            year = day.cwyear
			next if hash_weeks_years[[week, year]].nil?
            hash_weeks_years[[week, year]][:sum_planned] += hoursPerDay
            hash_weeks_years[[week, year]][:sum_earned]  += hoursPerDay * done_ratio
          end
        end
      end
    end
    ary_data_week_years = [['Semana', 'Costo Actual', 'Costo Planeado', 'Valor Ganado']]
    sum_real, sum_planned, sum_earned = 0,0,0
    ary_weeks_years.each do |k|
      v = hash_weeks_years[k]
      sum_real += time_entries_by_week_and_year.has_key?(k) ? time_entries_by_week_and_year[k] : 0
      sum_planned += v[:sum_planned]
      sum_earned  += v[:sum_earned]
      ary_data_week_years.push(
        [k[0].to_s + "/" + k[1].to_s,
         (sum_real * 100).round / 100.0,
         (sum_planned * 100).round / 100.0,
         (sum_earned * 100).round / 100.0])
    end
    cpi = calculate_performance_indicator(ary_data_week_years.last[3], ary_data_week_years.last[1])
    spi = calculate_performance_indicator(ary_data_week_years.last[3], ary_data_week_years.last[2])
    [ary_data_week_years, (cpi * 1000).round / 1000.0, (spi * 1000).round / 1000.0]
  end

  def self.retrive_data(project_or_version)
    if project_or_version.instance_of? Version
      project = project_or_version.project
      version = project_or_version
      time_entries_by_week_and_year =
		  project.time_entries.where(
              :issue_id => Issue.where(:fixed_version_id => version.id))
			  .group("tyear, tweek").order("tyear, tweek").select("sum(hours), tyear, tweek").to_sql
	  tmp = ActiveSupport::OrderedHash.new
	  result = ActiveRecord::Base.connection.execute(time_entries_by_week_and_year) rescue []
	  result.each do |v|
	    tmp[[v[2], v[1]]] = v[0]
	  end
	  time_entries_by_week_and_year = tmp
      issues = version.fixed_issues
    else
      project = project_or_version
      time_entries_by_week_and_year =
		  project.time_entries.group("tyear, tweek").order("tyear, tweek").select("sum(hours), tyear, tweek").to_sql
	  tmp = ActiveSupport::OrderedHash.new
	  result = ActiveRecord::Base.connection.execute(time_entries_by_week_and_year) rescue []
	  result.each do |v|
	    tmp[[v[2], v[1]]] = v[0]
	  end
	  time_entries_by_week_and_year = tmp
      issues = project.issues
    end
    return time_entries_by_week_and_year, issues
  end

  def self.calculate_performance_indicator(earned_value, denominator)
    denominator == 0 ? 0 : earned_value / denominator
  end
end
