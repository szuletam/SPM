class VersionIndicator

  attr_accessor :version, :issues, :maxdate, :mindate, :expected, :realized, :fulfillmen, :all_hours, :total_hours, :project_id

  def initialize(id, project_id)
    @version = Version.find(id)
		@issues = nil
    @maxdate = nil
    @mindate = nil
		@expected = 0
		@realized = 0
		@fulfillmen = 0
		@total_hours = 0
		@all_hours = 0
		@project_id = project_id
		self.issues_from_data(id)
		self.get_data
  end

  def get_data
		today = Date.today
		expected_value = 0
		self.total_hours = self.get_hours(self.version.id)
		self.issues.each do |issue|
			tmp_total = self.issues.size
			issue['estimated_hours'] = 1 if issue['estimated_hours'].nil? || issue['estimated_hours'] == 0
			if self.total_hours.to_f > 0 && ! issue['estimated_hours'].nil?
				self.realized += ((issue['estimated_hours'].to_f/self.total_hours.to_f) * issue['done_ratio'].to_i).round(2)
			elsif self.total_hours.to_f <= 0 || issue['estimated_hours'].nil?
				self.realized += ((issue['done_ratio'].to_f / tmp_total) rescue 0)
			end
		end

		if @maxdate.nil? || @mindate.nil?
			self.expected = 0
		else
			arr_project = {"start_date" => @mindate, "due_date" => @maxdate}
			self.expected = star_mto_to_mto_due(arr_project, today)
		end

		self.realized = 100 if self.realized > 100
		self.fulfillmen = ((self.realized / self.expected)*100).to_f.round(2) if self.expected > 0
		self.fulfillmen = 100 if self.fulfillmen > 100
		self.all_hours = get_all_hours
  end

	def get_hours(version_id)
		hours = 0
		Issue.where(:fixed_version_id => version_id).all.map{|i| hours += i.estimated_hours unless i.estimated_hours.nil? || !i.leaf?}
		return hours
	end

	def get_all_hours
		TimeEntry.joins(:issue).where("#{Issue.table_name}.fixed_version_id = ? AND time_entries.project_id = ?", self.version.id, self.project_id).sum(:hours).to_f.round(2)
	end

  def issues_from_data(version_id)
		@issues = Issue.where(:project_id => self.project_id).where(:fixed_version_id => version_id).where("rgt - lft = 1")
		@maxdate = Issue.where(:project_id => self.project_id).where(:fixed_version_id => version_id).where("rgt - lft = 1").maximum(:due_date)
		@mindate = Issue.where(:project_id => self.project_id).where(:fixed_version_id => version_id).where("rgt - lft = 1").minimum(:start_date)
  end

  def business_days(from, to)
		return 1 if from.nil? || to.nil? || from == '' || to == ''
    sql = "SELECT fx_weeklydays('%s'"%from
    sql << ",'%s')' value'"%to
    days = ActiveRecord::Base.connection.select_all(sql)
    return days[0]["value"]
  end

  def expected_version(date_start, date_end, today)
		return 0 if date_start.nil? || date_end.nil?
		if(date_start >= today)
	  	0
		else
			@planned_day = business_days(date_start, date_end)
			@today_days = business_days(date_start, today)
			@today_days = @today_days.to_f
			@planned_day = @planned_day.to_f
			expected_value = ((@today_days/@planned_day)*100.0).round(2)
			if  expected_value > 100
				expected_value = 100
			end
			return expected_value
		end
  end

  def star_mto_to_mto_due(issue, today)
    @planned_day = business_days(issue['start_date'],issue['due_date'])
    @today_days = business_days(issue['start_date'], today)
    @planned_day = @planned_day.to_s
    @planned_day = @planned_day.to_i
    @planned_day = @planned_day
    @today_days = @today_days.to_s
    @today_days = @today_days.to_i
    @today_days = @today_days
    expected_value = ((@today_days.to_f/@planned_day.to_f)*100).round(2)
    if  expected_value > 100
	  	expected_value = 100
		end
		if issue['start_date'].to_date > today
			expected_value = 0
		end
    return expected_value
  end

  def start_m_today
    return 0
  end

  def today_m_due_day
    return 100
  end
end
