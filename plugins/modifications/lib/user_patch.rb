module UserPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
		base.class_eval do
			include Redmine::SafeAttributes
			safe_attributes 'direction_id', 'director', 'general'
			belongs_to :direction
			has_many :issue_attendees, :class_name => 'IssueAttendant', :dependent => :delete_all
			validates_presence_of :direction_id
		end
  end
  module InstanceMethods
	end
end