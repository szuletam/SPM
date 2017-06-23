class EpmEasyProjectGantt < EpmEasyQueryBase

  def category_name
    @category_name ||= 'projects'
  end

  def default_settings
    @default_settings ||= { output: 'easy_gantt' }.with_indifferent_access
  end

  # Its project level
  #
  # def runtime_permissions(user)
  #   user.allowed_to_globally?(:view_global_easy_gantt)
  # end

  def query_class
    EasyGanttEasyIssueQuery
  end

  def show_path
    if RequestStore.store[:epm_easy_gantt_active]
      'easy_gantt/already_active_error'
    else
      RequestStore.store[:epm_easy_gantt_active] = true
      'easy_page_modules/projects/easy_project_gantt_show'
    end
  end

  def get_show_data(settings, user, **page_context)
    query = get_query(settings, user, page_context)

    if page_context[:project]
      can_view = user.allowed_to?(:view_easy_gantt, page_context[:project])
      query.opened_project = page_context[:project]
    else
      can_view = false
    end

    { query: query, can_view: can_view }
  end

end
