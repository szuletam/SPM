class OwnerProject < ActiveRecord::Base
  include Redmine::SafeAttributes

  table_name = 'owner_projects'

  belongs_to :member

  belongs_to :project

  safe_attributes 'member_id', 'project_id'
  validates_presence_of :member_id, :project_id
end
