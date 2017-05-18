module SettingPatch 
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do
		validate :start_ending_calendar
	end

	def start_ending_calendar
		if self.name == 'start_calendar_time'
			errors.add(:base, 'cualquier cosa') if self.value.to_i > Setting.end_calendar_time.to_i
		end
	end
  end
  module InstanceMethods
  end
end