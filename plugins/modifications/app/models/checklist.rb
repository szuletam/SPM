class Checklist < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :issue
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  has_one :comment, :as => :commented, :dependent => :delete
  if ActiveRecord::VERSION::MAJOR >= 4
    attr_protected :id
  end
  acts_as_event :datetime => :created_at,
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.issue_id}},
                :type => 'issue-closed',
                :title => Proc.new {|o| o.subject },
                :description => Proc.new {|o| "#{l(:field_issue)}:  #{o.issue.subject}" }

  acts_as_list

  validates_presence_of :subject
  validates_presence_of :position
  validates_numericality_of :position

  def self.recalc_issue_done_ratio(issue_id)
    issue = Issue.find(issue_id)
    return false if (Setting.issue_done_ratio != "issue_field") || !RedmineChecklists.settings[:issue_done_ratio] || issue.checklists.empty?
    done_checklist = issue.checklists.map{|c| c.is_done ? 1 : 0}
    done_ratio = (done_checklist.count(1) * 10) / done_checklist.count * 10
    issue.update_attribute(:done_ratio, done_ratio)
  end

  def self.old_format?(detail)
    (detail.old_value.is_a?(String) && detail.old_value.match(/^\[[ |x]\] .+$/).present?) ||
      (detail.value.is_a?(String) && detail.value.match(/^\[[ |x]\] .+$/).present?)
  end

  safe_attributes 'subject', 'position', 'issue_id', 'is_done'

  def editable_by?(usr=User.current)
    usr && (usr.allowed_to?(:edit_checklists, project) || (self.author == usr && usr.allowed_to?(:edit_own_checklists, project)))
  end

  def project
    self.issue.project if self.issue
  end

  def info
    "[#{self.is_done ? 'x' : ' ' }] #{self.subject.strip}"
  end

end
