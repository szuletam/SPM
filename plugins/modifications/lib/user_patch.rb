module UserPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
		base.class_eval do
			include Redmine::SafeAttributes
			safe_attributes 'direction_id', 'director', 'general', 'expiration_alert', 'position_id', 'boss_id'
			belongs_to :direction
			belongs_to :parent, :class_name => 'User', :foreign_key => 'boss_id', :primary_key => 'position_id', :inverse_of => :children
			has_many :children, :class_name => 'User', :foreign_key => 'boss_id', :primary_key => 'position_id', :inverse_of => :parent
			has_many :issue_attendees, :class_name => 'IssueAttendant', :dependent => :delete_all
			validates_presence_of :direction_id
			validates_uniqueness_of :position_id

			scope :roots, lambda {
				where("boss_id IS NULL")
			}

			scope :sorted, lambda { order("#{table_name}.position_id ASC") }

			send :include, ActiveRecord::Acts::Tree::InstanceMethods
		end
  end
  module InstanceMethods
		def projects_subalterns
			if @user_boss && @user_boss.id != self.id
				@user_boss = self
				@projects_subalterns = {}
			end
			@user_boss ||= self
			if @projects_subalterns && @projects_subalterns.any?
				@projects_subalterns
			else
				projects = []
				subalterns.each do |user|
					projects += user.projects unless user.projects.nil?
				end
				@projects_subalterns = projects.uniq
			end
		end

		def subalterns
			if @userboss && @userboss.id != self.id
				@userboss = self
				@subalterns = {}
			end
			if @subalterns && @subalterns.any?
				@subalterns
			else
				@userboss ||= self
				@subalterns ||= (descendants.any? ? descendants : [])
			end
		end

		def boss? project
			projects_subalterns.include? project
		end
	end
end