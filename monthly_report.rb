closed_status_ids = IssueStatus.where(:is_closed => true).pluck(:id)
join_tracker = "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
where_tracker = "#{Tracker.table_name}.is_in_roadmap = 1"


scope = Issue.joins(:project).joins(join_tracker).where(where_tracker).
    where("#{Project.table_name}.project_type_id = #{Setting.default_project_for_strategy.to_i}").
    where("#{Project.table_name}.status = #{Project::STATUS_ACTIVE}").
    where("#{Issue.table_name}.direction_id IS NOT NULL OR #{Issue.table_name}.direction_id != ''")

created   = scope.group(:direction_id).count
closed   = scope.where(:status_id => closed_status_ids).group(:direction_id).count
retarded = scope.open.where("#{Issue.table_name}.due_date < '#{Date.today.to_s(:db)}'").group(:direction_id).count

mrs = {}

created.each do |d, o|
  mrs[d] = {} unless mrs[d]
  mrs[d]['created'] = o if mrs[d]
end if created.any?

closed.each do |d, c|
  mrs[d] = {} unless mrs[d]
  mrs[d]['closed'] = c if mrs[d]
end if closed.any?

retarded.each do |d, r|
  mrs[d] = {} unless mrs[d]
  mrs[d]['retarded'] = r if mrs[d]
end if retarded.any?

report_date = Date.today - 1

mrs.each do |direction_id, issues|
  mr = MonthlyReport.new :report_date => report_date,
                         :created => (issues['created'] ? issues['created'] : 0),
                         :closed =>  (issues['closed'] ? issues['closed'] : 0),
                         :retarded => (issues['retarded'] ? issues['retarded'] : 0),
                         :direction_id => direction_id
  mr.save
end if mrs.any?

#closed_status_ids = IssueStatus.where(:is_closed => true).pluck(:id)
#join_tracker = "LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
#where_tracker = "#{Tracker.table_name}.is_in_roadmap = 1"
#
#
#scope = Issue.joins(:project).joins(join_tracker).where(where_tracker).
#    where("#{Project.table_name}.project_type_id = #{Setting.default_project_for_strategy.to_i}").
#    where("#{Project.table_name}.status = #{Project::STATUS_ACTIVE}").
#    where("#{Issue.table_name}.direction_id IS NOT NULL OR #{Issue.table_name}.direction_id != ''")
#
#for i in 1..11
#
#  month = i.to_s.length == 1 ? "0#{i}" : i.to_s
#  created = scope.where("#{Issue.table_name}.start_date BETWEEN '2016-01-01' AND '2016-#{month}-31'").group(:direction_id).count
#
#  mrs = {}
#
#  created.each do |d, o|
#    mrs[d] = {} unless mrs[d]
#    mrs[d]['created'] = o if mrs[d]
#  end if created.any?
#
#  mr_all = []
#  mrs.each do |direction_id, issues|
#    mr = MonthlyReport.new :report_date => "2016-#{month}-01",
#                            :created => (issues['created'] ? issues['created'] : 0),
#                            :closed =>  0,
#                            :retarded => 0,
#                            :direction_id => direction_id
#    mr_all << mr
#    mr.save
#  end if mrs.any?
#
#end