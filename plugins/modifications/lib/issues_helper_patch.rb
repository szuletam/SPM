module IssuesHelperPatch          
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)          
    base.class_eval do     
    alias_method_chain :render_descendants_tree, :modification
	  alias_method_chain :render_issue_tooltip, :modification 
	  alias_method_chain :render_issue_subject_with_tree, :modification

	  alias_method_chain :details_to_strings, :modification
    alias_method_chain :render_email_issue_attributes, :modification
    alias_method_chain :email_issue_attributes, :modification
    alias_method_chain :link_to_new_subtask, :modification
    alias_method_chain :update_issue_form_path, :modification
    alias_method_chain :issue_heading, :modification
	end

  def self.is_date?(text)
    begin
      return true if text.to_date
    rescue; end
    return false
  end
	
  end
  module InstanceMethods

    # Returns a link for adding a new subtask to the given issue
    def link_to_new_subtask_with_modification(issue)
      attrs = {
          :parent_issue_id => issue
      }
      attrs[:tracker_id] = issue.tracker unless issue.tracker.disabled_core_fields.include?('parent_issue_id')
      attrs[:origin_id] = issue.origin_id if issue.origin_id
      link_to(l(:button_add), new_project_issue_path(issue.project, :issue => attrs))
    end

    def email_issue_attributes_with_modification(issue, user)
      items = []
      %w(author status priority assigned_to category fixed_version).each do |attribute|
        unless issue.disabled_core_fields.include?(attribute+"_id")
          value_att = issue.send attribute
          if %w(priority fixed_version).include?(attribute)
            items << "#{l("field_#{attribute}")}: #{value_att}" unless value_att.blank?
          else
            items << "#{l("field_#{attribute}")}: #{value_att}" unless value_att.blank?
          end
        end
      end
      issue.visible_custom_field_values(user).each do |value|
        items << "#{value.custom_field.name}: #{show_value(value, false)}"
      end
      items
    end
  
    def render_email_issue_attributes_with_modification(issue, user, html = false)
      journal = issue.journals.order(:id).last
      return render_email_issue_attributes_without_modification(issue, user, html) unless journal
      details = journal.details
      return render_email_issue_attributes_without_modification(issue, user, html) unless details
      checklist_details = details.select{ |x| x.prop_key == 'checklist'}
      return render_email_issue_attributes_without_modification(issue, user, html) unless checklist_details.any?
      return render_email_issue_attributes_without_modification(issue, user, html) + details_to_strings(checklist_details, !html).join(html ? "<br/>".html_safe : "\n")
    end

    # Returns the path for updating the issue form
    # with project as the current project
    def update_issue_form_path_with_modification(project, issue, issue_with_project = true)
      options = {:format => 'js'}
      if issue.new_record?
        if !issue_with_project
          new_issue_path(options)
        elsif project
          new_project_issue_path(project, options)
        else
          new_issue_path(options)
        end
      else
        edit_issue_path(issue, options)
      end
    end

    def details_to_strings_with_modification(details, no_html = false, options = {})
      details_checklist, details_other = details.partition{ |x| x.prop_key == 'checklist' }
	  details_checklist.map do |detail|
        result = []
        diff = Hash.new([])
        if Checklist.old_format?(detail)
          result << "<b>#{l(:label_checklist_item)}</b> #{l(:label_checklist_changed_from)} #{detail.old_value} #{l(:label_checklist_changed_to)} #{detail.value}"
        else
          diff = JournalChecklistHistory.new(detail.old_value, detail.value).diff
        end

        if diff[:done].any?
          diff[:done].each do |item|
            result << "<b>#{l(:label_checklist_item)}</b> <input type='checkbox' #{item.is_done ? 'checked' : '' } disabled> <i>#{item[:subject]}</i> #{l(:label_checklist_done)}"
          end
        end

        if diff[:undone].any?
          diff[:undone].each do |item|
            result << "<b>#{l(:label_checklist_item)}</b> <input type='checkbox' #{item.is_done ? 'checked' : '' } disabled> <i>#{item[:subject]}</i> #{l(:label_checklist_undone)}"
          end
        end

        result = result.join('</li><li>').html_safe
        result = nil if result.blank?
        if result && no_html
          result = result.gsub /<\/li><li>/, "\n"
          result = result.gsub /<input type='checkbox'[^c^>]*checked[^>]*>/, '[x]'
          result = result.gsub /<input type='checkbox'[^c^>]*>/, '[ ]'
          result = result.gsub /<[^>]*>/, ''
        end
        result
      end.compact + details_to_strings_without_modification(details_other, no_html, options)
    end
  
	def render_issue_tooltip_with_modification(issue)
      @cached_label_status ||= l(:field_status)
      @cached_label_start_date ||= l(:field_start_date)
      @cached_label_due_date ||= l(:field_due_date)
      @cached_label_assigned_to ||= l(:field_assigned_to)
      @cached_label_priority ||= l(:field_priority)
      @cached_label_project ||= l(:field_project)
	  @cached_label_done_ratio ||= l(:field_done_ratio)
	  @cached_label_estimated_hours ||= l(:field_estimated_hours)
		
      link_to_issue(issue) + "<br /><br />".html_safe +
        "<strong>#{@cached_label_project}</strong>: #{link_to_project(issue.project)}<br />".html_safe +
        "<strong>#{@cached_label_status}</strong>: #{h(issue.status.name)}<br />".html_safe +
        "<strong>#{@cached_label_start_date}</strong>: #{format_date(issue.start_date)}<br />".html_safe +
        "<strong>#{@cached_label_due_date}</strong>: #{format_date(issue.due_date)}<br />".html_safe +
        "<strong>#{@cached_label_assigned_to}</strong>: #{h(issue.assigned_to)}<br />".html_safe +
        "<strong>#{@cached_label_priority}</strong>: #{h(issue.priority.name)}<br />".html_safe +
		"<strong>#{@cached_label_done_ratio}</strong>: #{h(issue.done_ratio.to_i)}%<br />".html_safe + 
		"<strong>#{@cached_label_estimated_hours}</strong>: #{h(issue.estimated_hours)}".html_safe
  end

    def issue_heading_with_modification(issue)
      h("##{issue.spmid}")
    end

    def render_issue_subject_with_tree_with_modification(issue)
      s = ''
      ancestors = issue.root? ? [] : issue.ancestors.to_a
      ancestors.each do |ancestor|
        s << '<div>' + content_tag('p', link_to_issue(ancestor, :project => (issue.project_id != ancestor.project_id)))
      end
      s << '<div>'
      subject = h(issue.subject)
      if issue.is_private?
        subject = content_tag('span', l(:field_is_private), :class => 'private') + ' ' + subject
      end
      subject = "#{issue.topic.first.detail}: " + subject if (issue.is_task? || issue.is_desition?) && issue.topic.first && !issue.topic.first.detail.blank?
      s << content_tag('h3', subject)
      s << '</div>' * (ancestors.size + 1)
      s.html_safe
    end
	 
	def render_descendants_tree_with_modification(issue)
      s = '<form><table class="list issues">'
      issue_list(issue.descendants.visible.preload(:status, :priority, :tracker).sort_by(&:lft)) do |child, level|
        css = "issue issue-#{child.id} hascontextmenu"
        css << " idnt idnt-#{level}" if level > 0
        s << content_tag('tr',
             content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
             content_tag('td', link_to_issue(child, :project => (issue.project_id != child.project_id)), :class => 'subject', :style => 'width: 50%') +
             content_tag('td', h(child.status)) +
             content_tag('td', link_to_user(child.assigned_to)) +
			 content_tag('td', format_date(child.start_date)) +
			 content_tag('td', format_date(child.due_date)) +
             content_tag('td', progress_bar(child.done_ratio, :legend => "#{child.done_ratio}%"), :class => "done_ratio"),
             :class => css)
      end
      s << '</table></form>'
      s.html_safe
    end
  end
end
