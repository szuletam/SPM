module ProjectsHelperPatch          
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)          
    base.class_eval do     
      #alias_method_chain :project_settings_tabs ,:modification
	  
	  def sidebar_project_queries
	    unless @sidebar_project_queries
	      @sidebar_project_queries = ProjectQuery.visible.order("#{Query.table_name}.name ASC").where("project_id IS NULL").all
        end
	    @sidebar_project_queries
      end

      def project_query_links(title, queries)
	    # links to #index on issues/show
	    url_params = controller_name == 'projects' ? {:controller => 'projects', :action => 'index'} : params
	    content_tag('h3', h(title)) +
	    queries.collect {|query|
	    css = 'query'
	    css << ' selected' if query == @query
	    link_to(h(query.name), url_params.merge(:query_id => query), :class => css)
	    }.join('<br />').html_safe
      end

      def render_sidebar_project_queries
	    out = ''.html_safe
	    queries = sidebar_project_queries.select {|q| !q.is_public?}
	    out << project_query_links(l(:label_my_queries), queries) if queries.any?
	    queries = sidebar_project_queries.select {|q| q.is_public?}
	    out << project_query_links(l(:label_query_plural), queries) if queries.any?
	    out
      end
    end
		
  end
  module InstanceMethods
	def project_settings_tabs_with_modification
	  tabs = [{:name => 'info', :action => :edit_project, :partial => 'projects/edit', :label => :label_information_plural},
				{:name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural},
				{:name => 'members', :action => :manage_members, :partial => 'projects/settings/members', :label => :label_member_plural},
				{:name => 'versions', :action => :manage_versions, :partial => 'projects/settings/versions', :label => :label_version_plural},
				{:name => 'categories', :action => :manage_categories, :partial => 'projects/settings/issue_categories', :label => :label_issue_category_plural},
				{:name => 'wiki', :action => :manage_wiki, :partial => 'projects/settings/wiki', :label => :label_wiki},
				{:name => 'repositories', :action => :manage_repository, :partial => 'projects/settings/repositories', :label => :label_repository_plural},
				{:name => 'boards', :action => :manage_boards, :partial => 'projects/settings/boards', :label => :label_board_plural},
				{:name => 'activities', :action => :manage_project_activities, :partial => 'projects/settings/activities', :label => :enumeration_activities}
				]
	  tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}
	end
  end
end
