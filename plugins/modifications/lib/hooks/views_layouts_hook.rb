class ViewsLayoutsHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context={})
	return javascript_include_tag(:checklists, :plugin => 'modifications') +
	  stylesheet_link_tag(:checklists, :plugin => 'modifications')
  end
end