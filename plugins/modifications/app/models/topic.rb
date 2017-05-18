class Topic < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :issue

  has_many :issue_topics

  has_many :related_issues, :through => :issue_topics

  validates_presence_of :content

  safe_attributes 'content', 'issue_id', 'presented_by', 'detail'

end
