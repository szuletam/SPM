module ContextMenusListsPatch    
	def self.included(base) # :nodoc:
		base.send(:include, InstanceMethods)          
		base.class_eval do          
		end
		def directions
			@id = params[:ids]
			@direction = Direction.find(@id)
			render :layout => false
		end

		def positions
			@id = params[:ids]
			@position = Direction.find(@id)
			render :layout => false
		end
		
		def committees
			@id = params[:ids]
			@committee = Committee.find(@id)
			render :layout => false
		end
	end
	module InstanceMethods
	end
end
