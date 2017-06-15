module UserPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
		base.class_eval do
			include Redmine::SafeAttributes
			safe_attributes 'direction_id', 'director', 'general', 'position_id'
			belongs_to :direction
			belongs_to :position, :class_name => 'Position', :primary_key => 'position_id', :foreign_key => 'position_id'
			has_many :issue_attendees, :class_name => 'IssueAttendant', :dependent => :delete_all
			validates_presence_of :direction_id
			validates_presence_of :position_id
			validates_uniqueness_of :position_id
		end
  end
  module InstanceMethods

		def projects_subalterns
			projects = []
			subalterns.each do |user|
				projects += user.projects unless user.projects.nil?
			end
			projects.uniq
		end

		def subalterns
			if position && position.descendants
				position.descendants.select{|position| !position.user.nil?}.map{|position| position.user}
			else
				[]
			end
		end

		def boss? project
			projects_subalterns.include? project
		end
	end
end