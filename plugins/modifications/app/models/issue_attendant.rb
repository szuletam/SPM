class IssueAttendant < ActiveRecord::Base
  include Redmine::SafeAttributes

  table_name = 'issue_attendants'

  belongs_to :issue

  belongs_to :user

  safe_attributes 'issue_id', 'user_id', 'invited'
end
