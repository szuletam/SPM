module IssuePatch    
  include Redmine::SafeAttributes
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)          
    base.class_eval do

      attr_accessor :old_checklists

      attr_reader :copied_from

      has_many :topics

      has_many :checklists,  lambda { order("#{Checklist.table_name}.position") }, :class_name => "Checklist", :dependent => :destroy, :inverse_of => :issue

      accepts_nested_attributes_for :checklists, :allow_destroy => true, :reject_if => proc { |attrs| attrs["subject"].blank? }
	  
	    alias_method_chain :new_statuses_allowed_to, :modification
	    alias_method_chain :recalculate_attributes_for, :modification
	    alias_method_chain :dates_derived?, :modification
	    alias_method_chain :css_classes, :modification

      safe_attributes 'checklists_attributes',
            :if => lambda {|issue, user| (user.allowed_to?(:done_checklists, issue.project) ||
                                          user.allowed_to?(:edit_checklists, issue.project))}

      safe_attributes 'origin_id', 'task_type_id', 'direction_id', 'compliance_date', 'diffused_date', 'others', 'spmid', 'recurrent'

      belongs_to :origin, :class_name => 'Committee'
      belongs_to :task_type
      belongs_to :direction
      belongs_to :vision

      has_many :issue_attendees, :class_name => 'IssueAttendant'
      has_many :issue_topics
      has_many :topic, :through => :issue_topics

      scope :in_roadmap, lambda {|*args|
        where_tracker = "#{Tracker.table_name}.is_in_roadmap = 1"
        joins(:tracker).where(where_tracker)
      }

      before_validation :remove_validation

      validates_presence_of :compliance_date, :if => Proc.new { |i| i.is_task? && i.status_id && i.status_id.to_s == '5' }

      #assigned_to_id Validation
      validate do |issue|
        issue.errors[:base] << I18n::t(:error_notes_by) if (issue.assigned_to_id.blank? || issue.assigned_to_id.nil?) && issue.is_committee?
        emptys_due_date = issue.topics.map{|topic| topic.issue_topics.map{|it| it.issue}}.flatten.select{|i| i && (i.due_date.nil? || i.due_date == '') && i.tracker_id == Setting.default_application_for_task.to_i}.any?
        issue.errors[:base] << I18n::t(:error_due_date_for_diffused) if issue.is_committee? && issue.status_id == 7 && emptys_due_date
      end

      before_save :change_diffused_date

      def self.by_direction(project)
        count_and_group_by(:project => project, :association => :direction)
      end

    end


    def getHighPripority
      1
    end

    def change_diffused_date
      #TODO: no quemar el status id con 7 sino configurarlo por la aplicacion
      if self.status_id_changed?
        #cambio en fecha de difusión y envio de mail de difusión
        if self.status_id == 7
          self.diffused_date = Date.today.to_s(:db)
          Mailer.issue_diffused(self)
        else
          self.diffused_date = ''
        end

        #fecha de cumplimiento
        if self.status_id == 5
          self.compliance_date = Date.today.to_s(:db) if self.compliance_date.blank?
        end
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

    def add_subtask_from_params(params, random)
      if ! params["recurrent_issue_#{random}"].nil?
        dates = Array.new
        url_data = CGI::parse(params["form_recurrence_data_#{random}"])
        case url_data["recurrence_type_#{random}"][0]
          when 'daily'
            date_start = url_data["recurrence_beginning_#{random}"][0].to_date
            step = url_data["recurrence_days_#{random}"][0].to_i
            if url_data["recurrence_ending_type_#{random}"][0] == "recurrence_ending_#{random}"
              iterations = url_data["recurrence_ending_#{random}"][0].to_i
              valid = true
              date_end = date_start
              while(valid)
                # validar que no puede crear una repeticion cada 7 dias, siendo no laboral si elije un sabado o un domingo como fecha de inicio
                if url_data["recurrence_days_type_#{random}"][0] == 'all_days'
                  dates << date_end
                  date_end = date_end + step.day
                elsif url_data["recurrence_days_type_#{random}"][0] == 'work_days'
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
            elsif url_data["recurrence_ending_type_#{random}"][0] == "recurrence_end_after_#{random}"
              date_end = url_data["recurrence_end_after_#{random}"][0].to_date
              i = 0
              while(date_start <= date_end)
                if url_data["recurrence_days_type_#{random}"][0] == 'all_days'
                  dates << date_start
                  date_start = date_start + step.day
                elsif url_data["recurrence_days_type_#{random}"][0] == 'work_days'
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
            wdays_selected = url_data["recurrence_days_of_week_#{random}"]
            date_start = url_data["recurrence_beginning_#{random}"][0].to_date
            if url_data["recurrence_ending_type_#{random}"][0] == "recurrence_ending_#{random}"
              iterations = url_data["recurrence_ending_#{random}"][0].to_i
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
            elsif url_data["recurrence_ending_type_#{random}"][0] == "recurrence_end_after_#{random}"
              date_end = url_data["recurrence_end_after_#{random}"][0].to_date
              while(date_start <= date_end)
                # validar que no puede crear una repeticion cada 7 dias, siendo no laboral si elije un sabado o un domingo como fecha de inicio
                if is_week_day(date_start,wdays_selected)
                  dates << date_start.to_date
                end
                date_start = date_start + 1.day;
              end
            end
          when 'monthly'
            date_start = url_data["recurrence_beginning_#{random}"][0].to_date
            step = url_data["recurrence_of_every_monthly_#{random}"][0].to_i
            day = url_data["recurrence_day_monthly_#{random}"][0].to_i
            if url_data["recurrence_ending_type_#{random}"][0] == "recurrence_ending_#{random}"
              iterations = url_data["recurrence_ending_#{random}"][0].to_i
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
            elsif url_data["recurrence_ending_type_#{random}"][0] == "recurrence_end_after_#{random}"
              date_end = url_data["recurrence_end_after_#{random}"][0].to_date
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
            date_start = url_data["recurrence_beginning_#{random}"][0].to_date
            if url_data["recurrence_ending_type_#{random}"][0] == "recurrence_ending_#{random}"
              iterations = url_data["recurrence_ending_#{random}"][0].to_i
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
            elsif url_data["recurrence_ending_type_#{random}"][0] == "recurrence_end_after_#{random}"
              date_end = url_data["recurrence_end_after_#{random}"][0].to_date
              while(date_start < date_end)
                dates << date_start
                date_start = date_start +  1.year
              end
            end
          else
        end
        dates.each do |date|
          new_issue = Issue.new
          self.attributes.each do |key, value|
            next if ["rgt", "lft", "created_on", "updated_on", "id"].include?(key)
            new_issue[key] = value
          end

          new_issue.start_date = date.to_date
          new_issue.due_date = date.to_date
          new_issue.parent_id = self.id
          new_issue.subject = self.subject
          new_issue.recurrent = true
          new_issue.save
        end
      else
      end
    end


    def id_and_subject
      "##{self.id.to_s}: #{self.subject}"
    end

    def remove_validation
      Issue.class_eval do
        _validators.delete(:assigned_to_id)

        _validate_callbacks.each do |callback|
          if callback.raw_filter.respond_to? :attributes
            callback.raw_filter.attributes.delete :assigned_to_id
          end
        end
      end
    end

	  def copy_checklists(arg)
      issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
      issue.checklists.each{ |checklist| Checklist.create(checklist.attributes.except('id','issue_id').merge(:issue => self).merge(:is_done => 0)) } if issue
    end

    def is_task?
      self.tracker_id == Setting.default_application_for_task.to_i
    end

    def is_desition?
      self.tracker_id == 5 #TODO: cambiar el 5 para no quemarlo
    end

    def is_committee?
      self.tracker_id == Setting.default_application_for_committee.to_i
    end

    def decrease_lock_version issue
      if issue.id
        new_lv = issue.lock_version - 1
        sql = "UPDATE issues SET lock_version = '#{new_lv}' WHERE id = '#{issue.id.to_s}' && lock_version = '#{issue.lock_version}'"
        ActiveRecord::Base.connection.execute(sql)
      end
    end

    def is_delayed?
      today = Date.today
      (!due_date.blank? &&  due_date < today)
    end

  end
  module InstanceMethods
    def css_classes_with_modification(user=User.current)

      if is_delayed? && !self.status.is_closed?
        self.priority = IssuePriority.find(getHighPripority)
      end

      s = "issue tracker-#{tracker_id} status-#{status_id} #{priority.try(:css_classes)}"
      s << ' closed' if closed?
      s << ' overdue' if overdue?
      s << ' child' if child?
      s << ' parent' unless leaf?
      s << ' private' if is_private?
      if user.logged?
        s << ' created-by-me' if author_id == user.id
        s << ' assigned-to-me' if assigned_to_id == user.id
        s << ' assigned-to-my-group' if user.groups.any? {|g| g.id == assigned_to_id}
      end
      s
    end

    def new_statuses_allowed_to_with_modification(user=User.current, include_default=false)
      if new_record? && @copied_from
        [default_status, @copied_from.status].compact.uniq.sort
      else
      initial_status = nil
        if new_record?
          initial_status = default_status
        elsif tracker_id_changed?
          if Tracker.where(:id => tracker_id_was, :default_status_id => status_id_was).any?
            initial_status = default_status
          elsif tracker.issue_status_ids.include?(status_id_was)
            initial_status = IssueStatus.find_by_id(status_id_was)
          else
            initial_status = default_status
          end
        else
          initial_status = status_was
        end

        initial_assigned_to_id = assigned_to_id_changed? ? assigned_to_id_was : assigned_to_id
        assignee_transitions_allowed = initial_assigned_to_id.present? &&
          (user.id == initial_assigned_to_id || user.group_ids.include?(initial_assigned_to_id))

        statuses = []
        statuses += IssueStatus.new_statuses_allowed(
          initial_status,
          user.admin ? Role.all.to_a : user.roles_for_project(project),
          tracker,
          author == user,
          assignee_transitions_allowed
        )
        statuses << initial_status unless statuses.empty?
        statuses << default_status if include_default || (new_record? && statuses.empty?)
        statuses = statuses.compact.uniq.sort
        if blocked?
          statuses.reject!(&:is_closed?)
        end
        if assigned_to_id && author_id != user.id
          statuses = statuses.select{|s| s.id != 8} unless user.allowed_to?(:close_foreing_issue, project)
        end
        statuses
      end
    end

    def dates_derived_with_modification?
      !leaf? && Setting.parent_issue_dates == 'derived' && !is_committee?
    end

    def recalculate_attributes_for_with_modification(issue_id)
      if issue_id && p = Issue.find_by_id(issue_id)
        return false if p.is_committee?
        if p.priority_derived?
          # priority = highest priority of open children
          if priority_position = p.children.open.joins(:priority).maximum("#{IssuePriority.table_name}.position")
            p.priority = IssuePriority.find_by_position(priority_position)
          else
            p.priority = IssuePriority.default
          end
        end

        if p.dates_derived?
          # start/due dates = lowest/highest dates of children
          p.start_date = p.children.minimum(:start_date)
          p.due_date = p.children.maximum(:due_date)
          if p.start_date && p.due_date && p.due_date < p.start_date
            p.start_date, p.due_date = p.due_date, p.start_date
          end
        end

        if p.done_ratio_derived?
          # done ratio = weighted average ratio of leaves
          unless Issue.use_status_for_done_ratio? && p.status && p.status.default_done_ratio
            child_count = p.children.count
            if child_count > 0
              average = p.children.where("estimated_hours > 0").average(:estimated_hours).to_f
              if average == 0
                average = 1
              end
              done = p.children.joins(:status).
                  sum("COALESCE(CASE WHEN estimated_hours > 0 THEN estimated_hours ELSE NULL END, #{average}) " +
                          "* (CASE WHEN is_closed = #{self.class.connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)").to_f
              progress = done / (average * child_count)
              p.done_ratio = progress.round
            end
          end
        end

        # ancestors will be recursively updated
        p.save(:validate => false)

      end
    end
  end
end