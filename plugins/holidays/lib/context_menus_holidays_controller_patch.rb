module ContextMenusHolidaysControllerPatch    
    def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)          
        base.class_eval do          
        end
		def holidays
			@id = params[:ids]
			@holiday = Holiday.find(@id)
			render :layout => false
		 end
    end
    module InstanceMethods
    end
end
