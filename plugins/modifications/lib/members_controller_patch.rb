module MembersControllerPatch           
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)                  
    base.class_eval do                    
	  helper :user_calendars
	  alias_method_chain :create, :modification
	  alias_method_chain :update, :modification
    end
	
  end    
  module InstanceMethods
    def create_with_modification
      members = []
      if params[:membership]
        user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids])
        user_ids << nil if user_ids.empty?
        user_ids.each do |user_id|
          member = Member.new(:project => @project, :user_id => user_id)
          member.set_editable_role_ids(params[:membership][:role_ids])
		  member.user_calendar_id = params[:membership][:user_calendar_id]
          members << member
        end
        @project.members << members
      end

      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.js {
          @members = members
          @member = Member.new
        }
        format.api {
          @member = members.first
          if @member.valid?
            render :action => 'show', :status => :created, :location => membership_url(@member)
          else
            render_validation_errors(@member)
          end
        }
      end
    end

    def update_with_modification
      if params[:membership]
        @member.set_editable_role_ids(params[:membership][:role_ids])
		    @member.user_calendar_id = params[:membership][:user_calendar_id]
        if params[:membership][:owner]
          @member.projects << @project unless @member.projects.include?(@project)
        else
          @member.projects.delete(@project) if @member.projects.include?(@project)
        end
      end
      saved = @member.save
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.js
        format.api {
          if saved
            render_api_ok
          else
            render_validation_errors(@member)
          end
        }
      end
    end
  end
end
