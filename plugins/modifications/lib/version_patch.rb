# AI Group SAS
module VersionPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do
	  alias_method_chain :due_date, :modification
	end
	
	def version_indicator
	  VersionIndicator.new self.id, self.project_id
	end
	
  end
  module InstanceMethods
    def due_date_with_modification
      fixed_issues.maximum('due_date')
    end
  end
end