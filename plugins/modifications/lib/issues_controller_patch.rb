module IssuesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      helper 'checklists'
      helper :issues
      helper :imports
      before_filter :authorize, :except => [:index, :new, :create, :get_done_ratio, :validate_recurrence, :validate_recurrence_for_committee, :table_row, :committee_data, :get_direction, :trackers_for_import, :attributes_for_import, :load_responsables]
      before_filter :get_time_entries, only: [:show]

      alias_method_chain :build_new_issue_from_params, :modification
      alias_method_chain :index, :modification
      alias_method_chain :create, :modification
      alias_method_chain :update, :modification
      alias_method_chain :redirect_after_create, :modification
      alias_method_chain :show, :modification
      alias_method_chain :new, :modification
      alias_method_chain :bulk_update, :modification
      alias_method_chain :edit, :modification

      before_filter :save_before_state, :only => [:update]

    end

    def get_direction
      render :text => (User.where(:id => params[:assigned_to]).first.direction_id rescue 0)
    end

    def committee_data
      render :json => (Committee.where(:name => params[:committee]).first rescue Committee.new)
    end

    def load_responsables
      @project = Project.find(params[:project_id])
      @select = params[:select]
    end

    def trackers_for_import
      render :partial => 'imports/trackers_for_import', :locals => params
    end

    def attributes_for_import
      @import = IssueImport.where(:user_id => User.current.id, :filename => params[:id]).first
      render :partial => 'imports/attributes', :locals => params
    end

    def table_row
      @project = Project.find(params[:project_id])
      @issue = Issue.find(params[:issue_id]) rescue Issue.new(:tracker_id => params[:tracker_id])
      @issue.project_id = @project.id
      @issue.tracker_id = params[:tracker_id]
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
      @priorities = IssuePriority.active
    end

    def validate_recurrence
      errors = Array.new
      errors << 'recurrence_type#empty' if !params.has_key?(:recurrence_type) || params[:recurrence_type].empty?
      errors << 'recurrence_beginning#empty' if !params.has_key?(:recurrence_beginning) || params[:recurrence_beginning].empty?

      if params[:recurrence_type] == 'daily'
        if !params.has_key?("recurrence_days") || params[:recurrence_days].empty?
          errors << 'recurrence_days#empty'
        elsif ! is_number?(params[:recurrence_days])
          errors << 'recurrence_days#integer_not_valid'
        elsif params[:recurrence_days].to_i <= 0
          errors << 'recurrence_days#greater_than_zero'
        elsif !params.has_key?("recurrence_days_type") || params[:recurrence_days_type].empty?
          errors << 'recurrence_days_type#empty'
        end
      elsif params[:recurrence_type] == 'weekly'
        if !params.has_key?("recurrence_days_of_week") || params[:recurrence_days_of_week].empty?
          errors << 'recurrence_days_of_week#empty'
        end
      elsif params[:recurrence_type] == 'monthly'
        if !params.has_key?("recurrence_day_monthly") || params[:recurrence_day_monthly].empty?
          errors << 'recurrence_day_monthly#empty'
        elsif ! is_number?(params[:recurrence_day_monthly])
          errors << 'recurrence_day_monthly#integer_not_valid'
        elsif params[:recurrence_day_monthly].to_i <= 0
          errors << 'recurrence_day_monthly#greater_than_zero'
        elsif !params.has_key?("recurrence_of_every_monthly") || params[:recurrence_of_every_monthly].empty?
          errors << 'recurrence_of_every_monthly#empty'
        elsif ! is_number?(params[:recurrence_of_every_monthly])
          errors << 'recurrence_of_every_monthly#integer_not_valid'
        elsif params[:recurrence_of_every_monthly].to_i <= 0
          errors << 'recurrence_of_every_monthly#greater_than_zero'
        end
      elsif params[:recurrence_type] == 'yearly'
        tmp_date = "#{Time.now.year}-#{params[:date][:recurrence_month_yearly]}-#{params[:date][:recurrence_day_yearly]}"
        if ! is_date?(tmp_date)
          errors << 'recurrence_month_yearly#date_not_valid'
        end
      else

      end
      if params[:recurrence_ending_type] == 'recurrence_ending'
        if !params.has_key?("recurrence_ending") || params[:recurrence_ending].empty?
          errors << 'recurrence_ending#empty'
        elsif ! is_number?(params[:recurrence_ending])
          errors << 'recurrence_ending#integer_not_valid'
        elsif params[:recurrence_ending].to_i <= 0
          errors << 'recurrence_ending#greater_than_zero'
        end
      elsif params[:recurrence_ending_type] == 'recurrence_end_after'
        if !params.has_key?("recurrence_end_after") || params[:recurrence_end_after].empty?
          errors << 'recurrence_end_after#empty'
        elsif ! is_date?(params[:recurrence_end_after])
          errors << 'recurrence_end_after#date_not_valid'
        elsif ! is_date?(params[:recurrence_beginning])
          errors << 'recurrence_beginning#date_not_valid'
        elsif params[:recurrence_beginning].to_date > params[:recurrence_end_after].to_date
          errors << 'recurrence_beginning#greater_than_recurrence_end_after'
        end
      end

      if errors.size > 0
        render :json => {:valid => false, :msg => display_errors(errors)}.to_json
      else
        render :json => {:valid => true, :msg => 'ok'}.to_json
      end
    end

    def validate_recurrence_for_committee
      random = params[:random]
      errors = Array.new
      errors << 'recurrence_type#empty' if !params.has_key?("recurrence_type_#{random}") || params["recurrence_type_#{random}"].empty?
      errors << 'recurrence_beginning#empty' if !params.has_key?("recurrence_beginning_#{random}") || params["recurrence_beginning_#{random}"].empty?

      if params["recurrence_type_#{random}"] == 'daily'
        if !params.has_key?("recurrence_days_#{random}") || params["recurrence_days_#{random}"].empty?
          errors << 'recurrence_days#empty'
        elsif ! is_number?(params["recurrence_days_#{random}"])
          errors << 'recurrence_days#integer_not_valid'
        elsif params["recurrence_days_#{random}"].to_i <= 0
          errors << 'recurrence_days#greater_than_zero'
        elsif !params.has_key?("recurrence_days_type_#{random}") || params["recurrence_days_type_#{random}"].empty?
          errors << 'recurrence_days_type#empty'
        end
      elsif params["recurrence_type_#{random}"] == 'weekly'
        if !params.has_key?("recurrence_days_of_week_#{random}") || params["recurrence_days_of_week_#{random}"].empty?
          errors << 'recurrence_days_of_week#empty'
        end
      elsif params["recurrence_type_#{random}"] == 'monthly'
        if !params.has_key?("recurrence_day_monthly_#{random}") || params["recurrence_day_monthly_#{random}"].empty?
          errors << 'recurrence_day_monthly#empty'
        elsif ! is_number?(params["recurrence_day_monthly_#{random}"])
          errors << 'recurrence_day_monthly#integer_not_valid'
        elsif params["recurrence_day_monthly_#{random}"].to_i <= 0
          errors << 'recurrence_day_monthly#greater_than_zero'
        elsif !params.has_key?("recurrence_of_every_monthly_#{random}") || params["recurrence_of_every_monthly_#{random}"].empty?
          errors << 'recurrence_of_every_monthly#empty'
        elsif ! is_number?(params["recurrence_of_every_monthly_#{random}"])
          errors << 'recurrence_of_every_monthly#integer_not_valid'
        elsif params["recurrence_of_every_monthly_#{random}"].to_i <= 0
          errors << 'recurrence_of_every_monthly#greater_than_zero'
        end
      elsif params["recurrence_type_#{random}"] == 'yearly'
        tmp_date = "#{Time.now.year}-#{params[:date]["recurrence_month_yearly_#{random}"]}-#{params[:date]["recurrence_day_yearly_#{random}"]}"
        if ! is_date?(tmp_date)
          errors << 'recurrence_month_yearly#date_not_valid'
        end
      else

      end
      if params["recurrence_ending_type_#{random}"] == "recurrence_ending_#{random}"
        if !params.has_key?("recurrence_ending_#{random}") || params["recurrence_ending_#{random}"].empty?
          errors << 'recurrence_ending#empty'
        elsif ! is_number?(params["recurrence_ending_#{random}"])
          errors << 'recurrence_ending#integer_not_valid'
        elsif params["recurrence_ending_#{random}"].to_i <= 0
          errors << 'recurrence_ending#greater_than_zero'
        end
      elsif params["recurrence_ending_type_#{random}"] == "recurrence_end_after_#{random}"
        if !params.has_key?("recurrence_end_after_#{random}") || params["recurrence_end_after_#{random}"].empty?
          errors << 'recurrence_end_after#empty'
        elsif ! is_date?(params["recurrence_end_after_#{random}"])
          errors << 'recurrence_end_after#date_not_valid'
        elsif ! is_date?(params["recurrence_beginning_#{random}"])
          errors << 'recurrence_beginning#date_not_valid'
        elsif params["recurrence_beginning_#{random}"].to_date > params["recurrence_end_after_#{random}"].to_date
          errors << 'recurrence_beginning#greater_than_recurrence_end_after'
        end
      end

      if errors.size > 0
        render :json => {:valid => false, :msg => display_errors(errors)}.to_json
      else
        render :json => {:valid => true, :msg => 'ok'}.to_json
      end
    end

    def display_errors(errors)
      display = Array.new
      errors.each do |error|
        error = error.split('#')
        display << l("label_#{error[0]}".to_sym) + "#{error_label(error[1])}"
      end
      display.join(', ')
    end

    def error_label(label)
      if(label == "empty")
        l(:label_error_validation_empty)
      elsif(label == "greater_than_zero")
        l(:label_error_validation_greater_than_zero)
      elsif(label == "integer_not_valid")
        l(:label_error_validation_integer_not_valid)
      elsif(label == "date_not_valid")
        l(:label_error_validation_date_not_valid)
      elsif(label == "greater_than_recurrence_end_after")
        l(:label_error_validation_greater_than_recurrence_end_after)
      else
        ''
      end
    end

    def is_number?(obj)
      obj.to_s == obj.to_i.to_s
    end

    def is_date?(text)
      begin
        return true if text.to_date
      rescue; end
      return false
    end

    def redirect_after_update
      if params[:save_and_continue]
        redirect_to edit_issue_path(@issue)
      else
        redirect_back_or_default issue_path(@issue, previous_and_next_issue_ids_params)
      end
    end

    def get_time_entries
      @time_entries = @issue.time_entries.preload(:user, :activity).order("#{TimeEntry.table_name}.spent_on DESC").limit(per_page_option)
    end

    def get_done_ratio
      @project = Project.find(params[:project_id])
      begin
        @issue = Issue.find(params[:issue_id])
        done_ratio = @issue.done_ratio
      rescue
        done_ratio = 0
      end
      render :text => done_ratio, :layout => false
    end

    def save_before_state
      @issue.old_checklists = @issue.checklists.to_json
    end
  end
  module InstanceMethods
    def index_with_modification
      retrieve_query
      sort_init(@query.sort_criteria.empty? ? [['start_date', 'desc']] : @query.sort_criteria)
      sort_update(@query.sortable_columns)
      @query.sort_criteria = sort_criteria.to_a

      if @query.valid?
        case params[:format]
          when 'csv', 'pdf'
            @limit = Setting.issues_export_limit.to_i
            if params[:columns] == 'all'
              @query.column_names = @query.available_inline_columns.map(&:name)
            end
          when 'atom'
            @limit = Setting.feeds_limit.to_i
          when 'xml', 'json'
            @offset, @limit = api_offset_and_limit
            @query.column_names = %w(author)
          else
            @limit = per_page_option
        end

        @issue_count = @query.issue_count
        @issue_pages = Redmine::Pagination::Paginator.new @issue_count, @limit, params['page']
        @offset ||= @issue_pages.offset
        @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                :order => sort_clause,
                                :format => params[:format],
                                :offset => @offset,
                                :limit => @limit)
        @issue_count_by_group = @query.issue_count_by_group

        respond_to do |format|
          format.html { render :template => 'issues/index', :layout => !request.xhr? }
          format.api  {
            Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
          }
          format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
          format.csv  { send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'issues.csv') }
          format.pdf  { send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf' }
        end
      else
        respond_to do |format|
          format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
          format.any(:atom, :csv, :pdf) { render(:nothing => true) }
          format.api { render_validation_errors(@query) }
        end
      end
    rescue ActiveRecord::RecordNotFound
      render_404

    end

    def show_with_modification
      @issue_with_project = params[:issue] && !params[:issue][:project_id].blank? ? true : false
      @journals = @issue.journals.includes(:user, :details).
          references(:user, :details).
          reorder(:created_on, :id).to_a
      @journals.each_with_index {|j,i| j.indice = i+1}
      @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
      Journal.preload_journals_details_custom_fields(@journals)
      @journals.select! {|journal| journal.notes? || journal.visible_details.any?}
      @journals.reverse! if User.current.wants_comments_in_reverse_order?

      @changesets = @issue.changesets.visible.preload(:repository, :user).to_a
      @changesets.reverse! if User.current.wants_comments_in_reverse_order?

      @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
      @priorities = IssuePriority.active
      @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
      @relation = IssueRelation.new



      issue_start_date = ''
      if @issue.start_date
        year = @issue.start_date.year.to_s[2..(@issue.start_date.year.to_s.length)]
        month = @issue.start_date.month.to_s.length == 1 ? "0#{@issue.start_date.month.to_s}" : @issue.start_date.month.to_s
        day = @issue.start_date.day.to_s.length == 1 ? "0#{@issue.start_date.day.to_s}" : @issue.start_date.day.to_s
        issue_start_date = "#{year}#{month}#{day}"
      end
      origin_name = @issue.origin ? @issue.origin.initial : ''

      if @issue.subject && origin_name == ''
        if comite = Committee.find_by(:name => @issue.subject)
          origin_name = comite.initial
        end
      end

      respond_to do |format|
        format.html {
          retrieve_previous_and_next_issue_ids
          render :template => 'issues/show'
        }
        format.api
        format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
        format.pdf  {
          send_file_headers! :type => 'application/pdf', :filename => "#{issue_start_date} #{origin_name}-#{@issue.spmid}.pdf"
        }
      end
    end

# Redirects user after a successful issue creation
    def redirect_after_create_with_modification
      if params[:save_and_continue]
        redirect_to edit_issue_path(@issue)
      else
        redirect_after_create_without_modification
      end
    end

    def create_with_modification
      @project ||= @issue.project if @issue.project
      unless User.current.allowed_to?(:add_issues, @issue.project, :global => true)
        raise ::Unauthorized
      end
      call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
      @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))

      @issue.issue_attendees = []
      users = @project.users.map{|u| u.id.to_s}
      unless params[:attendants].nil?
        params[:attendants].each do |ia|
          curr_attendant = IssueAttendant.new
          curr_attendant.user_id = ia
          curr_attendant.invited = ! users.include?(ia.to_s)
          @issue.issue_attendees << curr_attendant
        end
      end

#asigno la direccion del responsable a la tarea
      @issue.direction_id = @issue.is_task? && !@issue.assigned_to_id.blank? ? User.find(@issue.assigned_to_id).direction_id : ""
      issues_saveds = {}

      @issue.topics = []
      unless params[:topics].nil?
        params[:topics].each do |random, value|
          topic = Topic.new
          topic.content = value
          topic.presented_by = params[:topics_presented_by] && params[:topics_presented_by][random] ? params[:topics_presented_by][random] : ''
          topic.detail = params[:topics_detail] && params[:topics_detail][random] ? params[:topics_detail][random] : ''

          #guardando las tareas
          j = 0
          unless !params[:issue_topic].present? || params[:issue_topic][random].nil?
            while j < params[:issue_topic][random]["assigned_to_id"].size
              curr_issue = Issue.new
              curr_issue.project_id = params[:issue_topic][random]["project_id"][j]
              curr_issue.origin_id = (Committee.find_by_name(@issue.subject).id rescue Committee.first.id)
              curr_issue.subject = params[:issue_topic][random]["subject"][j]
              curr_issue.assigned_to_id = params[:issue_topic][random]["assigned_to_id"][j]
              curr_issue.direction_id = !curr_issue.assigned_to_id.blank? ? User.find(curr_issue.assigned_to_id).direction_id : ""
              curr_issue.start_date = @issue.start_date if @issue.start_date
              curr_issue.due_date = params[:issue_topic][random]["due_date"][j]
              curr_issue.status_id = 1 #TODO: No quemar 1 como estado abierto
              curr_issue.tracker_id = Setting.default_application_for_task.to_i
              curr_issue.author_id = User.current.id

              curr_issue.parent = @issue
              issues_saveds[params[:issue_topic][random]["random"][j]] = curr_issue
              issue_topic = IssueTopic.new
              issue_topic.issue =  curr_issue
              issue_topic.topic = topic

              topic.issue_topics << issue_topic

              j += 1
            end
          end

          #guardando las decisiones
          j = 0
          unless !params[:desition_topic].present? || params[:desition_topic][random].nil?
            while j < params[:desition_topic][random]["project_id"].size
              curr_issue = Issue.new
              project_id = !params[:desition_topic][random]["project_id"][j].blank? ?
                  params[:desition_topic][random]["project_id"][j] : @project.id
              curr_issue.project_id = project_id
              curr_issue.origin_id = (Committee.find_by_name(@issue.subject).id rescue Committee.first.id)
              curr_issue.subject = params[:desition_topic][random]["subject"][j]
              curr_issue.start_date = params[:desition_topic][random]["due_date"][j]
              curr_issue.due_date = params[:desition_topic][random]["due_date"][j]
              curr_issue.status_id = 8 #TODO: No quemar 8 como estado Cerrado
              curr_issue.tracker_id = 5
              curr_issue.author_id = User.current.id

              curr_issue.parent = @issue
              issues_saveds[params[:desition_topic][random]["random"][j]] = curr_issue
              desition_topic = IssueTopic.new
              desition_topic.issue =  curr_issue
              desition_topic.topic = topic

              topic.issue_topics << desition_topic

              j += 1
            end
          end

          next if topic.content.nil? || topic.content.empty?

          @issue.topics << topic

        end
      end

      if @issue.save
        issues_saveds.each do |random, is|
          is.add_subtask_from_params params, random
        end

        call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
        respond_to do |format|
          format.html {
            render_attachment_warning_if_needed(@issue)
            flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("##{Issue.find(@issue.id).spmid}", issue_path(@issue), :title => @issue.subject))
            redirect_after_create
          }
          format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
        end
        return
      else
        respond_to do |format|
          format.html {
            if @issue.project.nil?
              render_error :status => 422
            else
              render :action => 'new'
            end
          }
          format.api  { render_validation_errors(@issue) }
        end
      end
    end


    def bulk_update_with_modification
      @issues.sort!
      @copy = params[:copy].present?

      attributes = parse_params_for_bulk_update(params[:issue])
      copy_subtasks = (params[:copy_subtasks] == '1')
      copy_attachments = (params[:copy_attachments] == '1')

      if @copy
        unless User.current.allowed_to?(:copy_issues, @projects)
          raise ::Unauthorized
        end
        target_projects = @projects
        if attributes['project_id'].present?
          target_projects = Project.where(:id => attributes['project_id']).to_a
        end
        unless User.current.allowed_to?(:add_issues, target_projects)
          raise ::Unauthorized
        end
      else
        unless @issues.all?(&:attributes_editable?)
          raise ::Unauthorized
        end
      end

      unsaved_issues = []
      saved_issues = []

      if @copy && copy_subtasks
# Descendant issues will be copied with the parent task
# Don't copy them twice
        @issues.reject! {|issue| @issues.detect {|other| issue.is_descendant_of?(other)}}
      end

      @issues.each do |orig_issue|
        orig_issue.reload
        if @copy
          issue = orig_issue.copy({},
                                  :attachments => copy_attachments,
                                  :subtasks => copy_subtasks,
                                  :link => link_copy?(params[:link_copy])
          )
        else
          issue = orig_issue
        end
        journal = issue.init_journal(User.current, params[:notes])
        issue.safe_attributes = attributes
        call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })

        if issue.status_id && issue.status_id == 5
          issue.compliance_date = Date.today.to_s if issue.compliance_date.blank?
          issue.due_date = Date.today.to_s if issue.due_date.blank?
        end


        if issue.save
          saved_issues << issue
        else
          unsaved_issues << orig_issue
        end
      end

      if unsaved_issues.empty?
        flash[:notice] = l(:notice_successful_update) unless saved_issues.empty?
        if params[:follow]
          if @issues.size == 1 && saved_issues.size == 1
            redirect_to issue_path(saved_issues.first)
          elsif saved_issues.map(&:project).uniq.size == 1
            redirect_to project_issues_path(saved_issues.map(&:project).first)
          end
        else
          redirect_back_or_default _project_issues_path(@project)
        end
      else
        @saved_issues = @issues
        @unsaved_issues = unsaved_issues
        @issues = Issue.visible.where(:id => @unsaved_issues.map(&:id)).to_a
        bulk_edit
        render :action => 'bulk_edit'
      end
    end

    def update_with_modification
      return unless update_issue_from_params
      @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))

      #si esto al final es true es porque guardo
      saved = false

      topics_for_destroy = []
      issues_for_destroy = []

      #el topic conunter se calcula desde el formulario
      #si el counter es 0 es porque el acta no tiene topics y se eliminan todos
      if params[:topic_counter] && params[:topic_counter].to_i == 0
        @issue.topics.each do |topic|
          topic.issue_topics.each do |it|
            it.issue.destroy
          end
        end
        @issue.topics.destroy_all
      end

      #si existe un topico con id, ese topico debe ser actualizado
      #los topicos relacionados que no esten presentes fueron borrados desde el form de edit
      if params[:topics_ids].present? && params[:topics_ids].any?
        topics_for_update = params[:topics_ids].map{|k,v| v}
        topics_for_destroy = @issue.topics.map{|t| t.id.to_s} - topics_for_update
      end



      users = @project.users.map{|u| u.id.to_s}
      unless params[:attendants].nil?
        @issue.issue_attendees = []
        params[:attendants].each do |ia|
          curr_attendant = IssueAttendant.new
          curr_attendant.user_id = ia
          curr_attendant.invited = ! users.include?(ia.to_s)
          @issue.issue_attendees << curr_attendant
        end
      end

      issues_for_save = []
      issues_saveds = {}
      #asigno la direccion del responsable a la tarea
      @issue.direction_id = @issue.is_task? && !@issue.assigned_to_id.blank? ? User.find(@issue.assigned_to_id).direction_id : ""

      #se llenan los topicos para las actas
      unless params[:topics].nil?
        @issue.topics = []
        params[:topics].each do |random, value|
          topic = (Topic.find(params[:topics_ids][random]) rescue Topic.new)

          issues_for_update = []
          if params[:issue_topic] && params[:issue_topic][random] && params[:issue_topic][random]["id"] && params[:issue_topic][random]["id"].any?
            issues_for_update += params[:issue_topic][random]["id"]
          end

          if params[:desition_topic] && params[:desition_topic][random] && params[:desition_topic][random]["id"] && params[:desition_topic][random]["id"].any?
            issues_for_update += params[:desition_topic][random]["id"]
          end

          if params[:issue_topic] || params[:desition_topic]
            issues_for_destroy += topic.issue_topics.map{|it| it.issue_id.to_s} - issues_for_update
          end

          topic.content = value
          topic.presented_by = params[:topics_presented_by] && params[:topics_presented_by][random] ? params[:topics_presented_by][random] : ''
          topic.detail = params[:topics_detail] && params[:topics_detail][random] ? params[:topics_detail][random] : ''
          j = 0

          if params[:issue_topic] || params[:desition_topic]
            topic.issue_topics.destroy_all
            topic.issue_topics = []
          end

          unless !params[:issue_topic].present? || params[:issue_topic][random].nil?
            while j < params[:issue_topic][random]["assigned_to_id"].size

              curr_issue = (Issue.find(params[:issue_topic][random]["id"][j]) rescue Issue.new)

              curr_issue.project_id = params[:issue_topic][random]["project_id"][j]
              curr_issue.origin_id = (Committee.find_by_name(@issue.subject).id rescue Committee.first.id)
              curr_issue.subject = params[:issue_topic][random]["subject"][j]
              curr_issue.assigned_to_id = params[:issue_topic][random]["assigned_to_id"][j]
              curr_issue.direction_id = !curr_issue.assigned_to_id.blank? ? User.find(curr_issue.assigned_to_id).direction_id : ""
              curr_issue.start_date = @issue.start_date
              curr_issue.due_date = params[:issue_topic][random]["due_date"][j]
              curr_issue.status_id = 1 if curr_issue.new_record? #TODO: No quemar 1 como estado abierto
              curr_issue.tracker_id = Setting.default_application_for_task.to_i
              curr_issue.author_id = User.current.id

              curr_issue.parent_id = @issue.id

              if curr_issue.new_record?
                issues_saveds[params[:issue_topic][random]["random"][j]] = curr_issue
              else
                issues_for_save << curr_issue
              end


              issue_topic = IssueTopic.new
              issue_topic.issue =  curr_issue
              issue_topic.topic = topic

              topic.issue_topics << issue_topic

              j += 1
            end
          end

          j = 0
          unless !params[:desition_topic].present? || params[:desition_topic][random].nil?
            while j < params[:desition_topic][random]["project_id"].size

              curr_issue = (Issue.find(params[:desition_topic][random]["id"][j]) rescue Issue.new)

              project_id = !params[:desition_topic][random]["project_id"][j].blank? ?
                  params[:desition_topic][random]["project_id"][j] : @project.id
              curr_issue.project_id = project_id
              curr_issue.origin_id = (Committee.find_by_name(@issue.subject).id rescue Committee.first.id)
              curr_issue.subject = params[:desition_topic][random]["subject"][j]
              curr_issue.start_date = @issue.start_date
              curr_issue.due_date = params[:desition_topic][random]["due_date"][j]
              curr_issue.status_id = 8 if curr_issue.new_record? #TODO: No quemar 8 como estado cerrado
              curr_issue.tracker_id = 5
              curr_issue.author_id = User.current.id

              curr_issue.parent_id = @issue.id

              if curr_issue.new_record?
                issues_saveds[params[:desition_topic][random]["random"][j]] = curr_issue
              else
                issues_for_save << curr_issue
              end


              desition_topic = IssueTopic.new
              desition_topic.issue =  curr_issue
              desition_topic.topic = topic

              topic.issue_topics << desition_topic

              j += 1
            end
          end

          next if topic.content.nil? || topic.content.empty?

          @issue.topics << topic
        end
      end

      begin
        saved = save_issue_with_child_records
      rescue ActiveRecord::StaleObjectError
        @conflict = true
        if params[:last_journal_id]
          @conflict_journals = @issue.journals_after(params[:last_journal_id]).to_a
          @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
        end
      end

      if saved
#guardo los issue topics que son para actualizar
        issues_for_save.each do |curr_issue|
          curr_issue.save
        end

#creo las actividades recurrentes desde los params
        issues_saveds.each do |random, is|
          is.add_subtask_from_params params, random
        end

#agrego a los issues para borrar los issues de los topicos que son para destruir
        Topic.where(:id => topics_for_destroy).each do |topic|
          issues_for_destroy += topic.issue_topics.map{|it| it.issue_id.to_s}
        end

#borro los topics que son para destruir
        Topic.where(:id => topics_for_destroy).destroy_all if topics_for_destroy.any?

#borro los issues topics que son para destruir
        Issue.where(:id => issues_for_destroy).destroy_all if issues_for_destroy.any?

        render_attachment_warning_if_needed(@issue)
        flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

        respond_to do |format|
          format.html { redirect_after_update }
          format.api  { render_api_ok }
        end
      else
        respond_to do |format|
          format.html { render :action => 'edit' }
          format.api  { render_validation_errors(@issue) }
        end
      end
    end

    def build_new_issue_from_params_with_modification
      if params[:copy_from] && params[:id].blank? && params[:issue].blank?
        params[:issue] = {:checklists_attributes => {}}
        begin
          @copy_from = Issue.visible.find(params[:copy_from])
          @copy_from.checklists.each_with_index do |checklist_item, index|
            params[:issue][:checklists_attributes][index.to_s] = {:is_done => checklist_item.is_done,
                                                                  :subject => checklist_item.subject,
                                                                  :position => checklist_item.position}
          end
        rescue ActiveRecord::RecordNotFound
          render_404
          return
        end
      end
      build_new_issue_from_params_without_modification
    end
  end

  def new_with_modification
    @issue_with_project = params[:issue] && !params[:issue][:project_id].blank? ? true : false
    @project ||= Project.find(params[:issue][:project_id]) if  params[:issue] && !params[:issue][:project_id].blank?
    @parent_issue = (Issue.find(params[:issue][:parent_issue_id]) rescue nil)
    new_without_modification
  end
  def edit_with_modification
    @issue_with_project = params[:issue] && !params[:issue][:project_id].blank? ? true : false
    edit_without_modification
  end
end
