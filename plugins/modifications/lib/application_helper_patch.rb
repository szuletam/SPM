module ApplicationHelperPatch          
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)          
    base.class_eval do     
      alias_method_chain :render_project_jump_box ,:modification
      alias_method_chain :javascript_heads ,:modification
      alias_method_chain :textilizable ,:modification
      alias_method_chain :link_to_issue ,:modification
	end
		
  end
  module InstanceMethods

    def link_to_issue_with_modification(issue, options={})
      title = nil
      subject = nil
      text = "##{issue.spmid}"
      if options[:subject] == false
        title = issue.subject.truncate(60)
      else
        subject = issue.subject
        if truncate_length = options[:truncate]
          subject = subject.truncate(truncate_length)
        end
      end
      only_path = options[:only_path].nil? ? true : options[:only_path]
      s = link_to(text, issue_url(issue, :only_path => only_path),
                  :class => issue.css_classes, :title => title)
      s << ": #{issue.topic.first.detail}" if (issue.is_task? || issue.is_desition?) && issue.topic.first && !issue.topic.first.detail.blank? && subject
      s << h(": #{subject}") if subject
      s = h("#{issue.project} - ") + s if options[:project]
      s
    end

    def javascript_heads_with_modification
      #tags = javascript_include_tag('jquery-1.11.1-ui-1.11.0-ujs-3.1.4', 'yui3/build/yui/yui-min.js', 'yui/build/yahoo/yahoo-min.js','yui/build/yahoo-dom-event/yahoo-dom-event.js','jstree/jstree.min.js', 'application', 'responsive')
      tags = javascript_include_tag('jquery-1.11.1-ui-1.11.0-ujs-3.1.4', 'jstree/jstree.min.js', 'application', 'responsive')
	  unless User.current.pref.warn_on_leaving_unsaved == '0'
        tags << "\n".html_safe + javascript_tag("$(window).load(function(){ warnLeavingUnsaved('#{escape_javascript l(:text_warn_on_leaving_unsaved)}'); });")
      end
      tags
    end

    # Formats text according to system settings.
    # 2 ways to call this method:
    # * with a String: textilizable(text, options)
    # * with an object and one of its attribute: textilizable(issue, :description, options)
    def textilizable_with_modification(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      case args.size
        when 1
          obj = options[:object]
          text = args.shift
        when 2
          obj = args.shift
          attr = args.shift
          text = obj.send(attr).to_s
        else
          raise ArgumentError, 'invalid arguments to textilizable'
      end
      return '' if text.blank?
      project = options[:project] || @project || (obj && obj.respond_to?(:project) ? obj.project : nil)
      @only_path = only_path = options.delete(:only_path) == false ? false : true

      text = text.dup
      macros = catch_macros(text)
      text = Redmine::WikiFormatting.to_html(Setting.text_formatting, text, :object => obj, :attribute => attr)

      @parsed_headings = []
      @heading_anchors = {}
      @current_section = 0 if options[:edit_section_links]

      parse_sections(text, project, obj, attr, only_path, options)
      text = parse_non_pre_blocks(text, obj, macros) do |text|
        [:parse_inline_attachments, :parse_wiki_links].each do |method_name|
          send method_name, text, project, obj, attr, only_path, options
        end
      end
      parse_headings(text, project, obj, attr, only_path, options)

      if @parsed_headings.any?
        replace_toc(text, @parsed_headings)
      end

      text.html_safe
    end

    def render_project_jump_box_with_modification
	  return unless User.current.logged?
	  if User.current.admin?
	    projects = Project.active.order("lft, name").all
	  else
        projects = User.current.projects.active.select(:id, :name, :identifier, :lft, :rgt).to_a
	  end
      if projects.any?
        options =
          ("<option value=''>#{ l(:label_jump_to_a_project) }</option>" +
           '<option value="" disabled="disabled">---</option>').html_safe

        options << project_tree_options_for_select(projects, :selected => @project) do |p|
          { :value => project_path(:id => p, :jump => current_menu_item) }
        end

        content_tag( :span, nil, :class => 'jump-box-arrow') +
        select_tag('project_quick_jump_box', options, :onchange => 'if (this.value != \'\') { window.location = this.value; }')
      end
	end
  end
end
