class IssueTopic < ActiveRecord::Base
  include Redmine::SafeAttributes

  table_name = 'issue_topics'

  belongs_to :issue

  belongs_to :topic

  safe_attributes 'topic_id', 'issue_id'
end
