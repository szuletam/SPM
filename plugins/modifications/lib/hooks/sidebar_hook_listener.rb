class SidebarHookListener < Redmine::Hook::ViewListener
	render_on :view_layouts_base_content, :partial => "common/hide_button"
end