class MonthlyReport < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :direction

  safe_attributes 'report_date',
      'created',
      'closed',
      'retarded',
      'direction_id'

  def self.between(start_date, due_date)
    where(["#{MonthlyReport.table_name}.report_date BETWEEN ? AND ?", start_date , due_date])
  end

  def self.get_last_month
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

    mrs_return = {}
    mrs.each do |direction_id, issues|
      mr = MonthlyReport.new :report_date => report_date,
                             :created => (issues['created'] ? issues['created'] : 0),
                             :closed =>  (issues['closed'] ? issues['closed'] : 0),
                             :retarded => (issues['retarded'] ? issues['retarded'] : 0),
                             :direction_id => direction_id
      mrs_return[direction_id] = mr
    end if mrs.any?

    mrs_return

  end

end
