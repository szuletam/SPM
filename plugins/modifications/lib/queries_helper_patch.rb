module QueriesHelperPatch          
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do               
	  alias_method_chain :column_value, :modification
	  alias_method_chain :retrieve_query, :modification 
	  alias_method_chain :csv_value, :modification
	  alias_method_chain :column_header, :modification
	  alias_method_chain :csv_content, :modification
	end
  end
  module InstanceMethods

		def csv_content_with_modification(column, issue)
			if issue && issue.is_a?(Issue) && column.name == :id
				value = issue.spmid
			else
				value = column.value_object(issue)
			end

			if value.is_a?(Array)
				value.collect {|v| csv_value(column, issue, v)}.compact.join(', ')
			else
				csv_value(column, issue, value)
			end
		end

		def column_header_with_modification(column)
			column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
																				:class => "table_header_#{column.name.to_s}",
																				:default_order => column.default_order) :
					content_tag('th', h(column.caption), :class => "table_header_#{column.name.to_s}")
		end
    def retrieve_query_with_modification(type='i')
	  if !params[:query_id].blank?
		cond = "project_id IS NULL"
		cond << " OR project_id = #{@project.id}" if @project
		if type == 'i'
		  @query = IssueQuery.where(cond).find(params[:query_id])
		  raise ::Unauthorized unless @query.visible?
		elsif type == 'p'
		  begin
			@query = ProjectQuery.where(cond).find(params[:query_id])
		  rescue
			raise ::Unauthorized 
		  end
		elsif type == 't'
		  begin
			@query = TimeEntryQuery.where(cond).find(params[:query_id])
		  rescue
		    raise ::Unauthorized 
		  end
		else 
		  # NONE
		end
		@query.project = @project
		session[:query] = {:id => @query.id, :project_id => @query.project_id} unless @query.instance_of?(ProjectQuery)
		sort_clear
	  elsif api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
		# Give it a name, required to be valid
		@query = IssueQuery.new(:name => "_")
		@query.project = @project
		@query.build_from_params(params) 
		session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
	  else
		# retrieve from session
		@query = IssueQuery.find_by_id(session[:query][:id]) if session[:query][:id]
		@query ||= IssueQuery.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names])
		@query.project = @project
	  end
    end
		
	def render_query_columns_selection_project(query, options={})
	  tag_name = (options[:name] || 'c') + '[]'
	  render :partial => 'project_queries/columns', :locals => {:query => query, :tag_name => tag_name}
	end
		
	def column_value_with_modification(column, issue, value)	
	  case value.class.name
	  when 'String'
		if column.name == :subject
			value = "#{issue.topic.first.detail}: " + value if (issue.is_task? || issue.is_desition?) && issue.topic.first && !issue.topic.first.detail.blank?
		  link_to(h(value), :controller => 'issues', :action => 'show', :id => issue)
		elsif column.name == :description && !issue.is_a?(Project)
		  issue.description? ? content_tag('div', textilizable(issue, :description), :class => "wiki") : ''
		elsif column.name == :description && issue.is_a?(Project)
		  issue.description? ? content_tag('div', truncate(ActionView::Base.full_sanitizer.sanitize(issue.description), :length => 80), :class => "wiki") : ''
		elsif column.name == :name && User.current.allowed_to?(:view_project, issue)
		  link_to(h(value), {:controller => 'projects', :action => 'show', :id => issue}, :class => "#{issue.css_classes} #{User.current.member_of?(issue) ? '' : ''}")
		else
		  h(value)
		end
	  when 'Time'
		format_time(value)
	  when 'Date'
		format_date(value)
	  when 'Fixnum'
		if column.name == :id && issue.class.name == "Project"
		  link_to "#{issue.id}", project_path(issue)
		elsif column.name == :id
		  link_to_issue(issue, :subject => false)
		elsif column.name == :done_ratio || column.name == :project_done_ratio
		  content_tag("div", progress_bar(value, :width => '80px', :legend => "#{value}%"), :style => "width: 80%; margin-left: 10%;")
		else
		  value.to_s
		end
	  when 'Float'
		sprintf "%.2f", value
	  when 'User'
		link_to_user value
      when 'Project'
		#link_to_project value
		link_to "#{issue.project.id}-#{issue.project.name}", project_path(issue.project)
	  when 'Version'
		link_to(h(value), :controller => 'versions', :action => 'show', :id => value)
	  when 'TrueClass'
		l(:general_text_Yes)
	  when 'FalseClass'
		l(:general_text_No)
	  when 'Issue'
		value.visible? ? link_to_issue(value) : "##{value.id}"
	  when 'IssueRelation'
		other = value.other_issue(issue)
		content_tag('span',
		(l(value.label_for(issue)) + " " + link_to_issue(other, :subject => false, :tracker => false)).html_safe,
		:class => value.css_classes_for(issue))
	  else
		h(value)
	  end
	end

	def csv_value_with_modification(column, object, value)
	  format_object(value, false) do |value|
				
	  case value.class.name
		when 'Float'
		  sprintf("%.2f", value).gsub('.', l(:general_csv_decimal_separator))
		when 'IssueRelation'
		  other = value.other_issue(object)
		  l(value.label_for(object)) + " ##{other.id}"
		when 'Issue'
		  if object.is_a?(TimeEntry)
			"#{value.tracker} ##{value.id}: #{value.subject}"
		  else
			value.id
		  end
		else
		  if column.name == :project
			"#{value.id}-#{value.name}"
		  else
			value
		  end
		end
	  end
	end
  end
end
