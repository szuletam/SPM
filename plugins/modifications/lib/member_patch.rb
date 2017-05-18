# AI Group SAS
module MemberPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do
	  include Redmine::SafeAttributes
	  safe_attributes 'user_calendar_id'
	  belongs_to :user_calendar
		has_many :owner_projects
		has_many :projects, :through => :owner_projects

		def self.get_owner_projects(user)
			return [] unless user
			projects = []
			decendants = []
			Member.where(:user_id => user.id).select{|m| m.projects.any? }.map{|m| projects += m.projects.active.select{|p| p.is_strategy? } }
			projects.each {|p| decendants += p.self_and_descendants }
			decendants.uniq
		end

	end

	def scheduled_by_day(calendar_id,week_day=1)
	  val = ActiveRecord::Base.connection.select_all("SELECT SUM(due + 1 - init) AS day_hours
								FROM user_calendar_hours 
								WHERE user_calendar_id = #{calendar_id.nil? ? 0 : calendar_id} 
												AND week_day = #{week_day}")
	  val[0]["day_hours"].to_i rescue 0
	end


	
  end
  module InstanceMethods
       
  end
end