module TimelogControllerPatch           
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)                  
    base.class_eval do                    
      alias_method_chain :create, :done_ratio
      alias_method_chain :update, :done_ratio
    end
  end    
  module InstanceMethods
    def create_with_done_ratio
	  @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
      @time_entry.safe_attributes = params[:time_entry]
      if @time_entry.project && !User.current.allowed_to?(:log_time, @time_entry.project)
        render_403
        return
      end
      begin
	    if @issue.leaf?
		  @time_entry.done_ratio = params[:issue][:done_ratio]
		  @issue.init_journal(User.current, '')
		  @issue.done_ratio = params[:issue][:done_ratio]
		  @issue.save
	    end
	  rescue; end
	  
      call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

      if @time_entry.save
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_create)
            if params[:continue]
              options = {
                :time_entry => {
                  :project_id => params[:time_entry][:project_id],
                  :issue_id => @time_entry.issue_id,
                  :activity_id => @time_entry.activity_id
                },
                :back_url => params[:back_url]
              }
              if params[:project_id] && @time_entry.project
                redirect_to new_project_time_entry_path(@time_entry.project, options)
              elsif params[:issue_id] && @time_entry.issue
                redirect_to new_issue_time_entry_path(@time_entry.issue, options)
              else
                redirect_to new_time_entry_path(options)
              end
            else
              redirect_back_or_default project_time_entries_path(@time_entry.project)
            end
          }
          format.api  { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
        end
      else
        respond_to do |format|
          format.html { render :action => 'new' }
          format.api  { render_validation_errors(@time_entry) }
        end
      end
	end
	  
    def update_with_done_ratio
	  @time_entry.safe_attributes = params[:time_entry]

      call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
	  
	  @issue = @time_entry.issue
	  if @issue.leaf?
		@time_entry.done_ratio = params[:issue][:done_ratio]
	  end
      @issue.init_journal(User.current, '')
      @issue.attributes = params[:issue] 
      if @time_entry.save
	    @issue.save
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_update)
            redirect_back_or_default project_time_entries_path(@time_entry.project)
          }
          format.api  { render_api_ok }
        end
      else
        respond_to do |format|
          format.html { render :action => 'edit' }
          format.api  { render_validation_errors(@time_entry) }
        end
      end
    end
  end
end
