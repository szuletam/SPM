module ContextMenusControllerPatch    
    def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)          
        base.class_eval do
          alias_method_chain :issues ,:modification
        end

        def projects
          @id = params[:id]
          @project = Project.find(params[:id])
          @back = back_url
          render :layout => false
        end

    end
    module InstanceMethods
      def issues_with_modification

        if (@issues.size == 1)
          @issue = @issues.first
        end

        @back = back_url

        @issue_ids = @issues.map(&:id).sort

        @allowed_statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)

        @can = {:edit => @issues.all?(&:attributes_editable?),
                :log_time => (@project && User.current.allowed_to?(:log_time, @project)),
                :copy => User.current.allowed_to?(:copy_issues, @projects) && Issue.allowed_target_projects.any?,
                :add_watchers => User.current.allowed_to?(:add_issue_watchers, @projects),
                :delete => @issues.all?(&:deletable?)
        }

        if params[:change_status]
          render 'change_status', :layout => false
        else
          if @project
            if @issue
              @assignables = @issue.assignable_users
            else
              @assignables = @project.assignable_users
            end
          else
            #when multiple projects, we only keep the intersection of each set
            @assignables = @projects.map(&:assignable_users).reduce(:&)
          end
          @trackers = @projects.map {|p| Issue.allowed_target_trackers(p) }.reduce(:&)
          @versions = @projects.map {|p| p.shared_versions.open}.reduce(:&)

          @priorities = IssuePriority.active.reverse

          @options_by_custom_field = {}
          if @can[:edit]
            custom_fields = @issues.map(&:editable_custom_fields).reduce(:&).reject(&:multiple?)
            custom_fields.each do |field|
              values = field.possible_values_options(@projects)
              if values.present?
                @options_by_custom_field[field] = values
              end
            end
          end

          @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)
          render :layout => false
        end
      end

    end
end
