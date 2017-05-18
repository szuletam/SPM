module TimeEntryPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
    base.class_eval do      
	  attr_accessor :done_ratio
	  validates_presence_of :comments
	  validate :max_hours
    end
	def max_hours
	  unless hours.nil?
	    errors.add :base, l(:error_time_entry_hours_max) if hours > 24
	  end
	end
  end
  module InstanceMethods
  end
end
