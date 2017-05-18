class WorkTimeIssue < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'user_id', 'issue_id'
  
  belongs_to :issue
  belongs_to :user
end
