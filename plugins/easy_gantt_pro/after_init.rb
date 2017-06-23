easy_extensions = Redmine::Plugin.installed?(:easy_extensions)
app_dir = File.join(File.dirname(__FILE__), 'app')
lib_dir = File.join(File.dirname(__FILE__), 'lib', 'easy_gantt_pro')

# Redmine patches
patch_path = File.join(lib_dir, 'redmine_patch', '**', '*.rb')
Dir.glob(patch_path).each do |file|
  require file
end

if easy_extensions
  ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_page_modules')

  EasyExtensions::PatchManager.register_easy_page_helper 'EasyGanttHelper'
  EpmEasyGlobalGantt.register_to_page('my-page', plugin: :easy_gantt_pro)
  EpmEasyProjectGantt.register_to_page('project-overview', plugin: :easy_gantt_pro)
end

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_gantt_pro/proposer' if easy_extensions
end

ActionDispatch::Reloader.to_prepare do
  require_dependency 'easy_gantt_pro/hooks'
end

Redmine::MenuManager.map :easy_gantt do |menu|
  menu.delete(:add_task)
  menu.delete(:critical)
  menu.delete(:baseline)

  menu.push(:baseline, 'javascript:void(0)',
    param: :project_id,
    caption: :'easy_gantt.button.create_baseline',
    html: { icon: 'icon-projects' },
    if: proc { |project|
      project.present? &&
      Redmine::Plugin.installed?(:easy_baseline) &&
      project.module_enabled?('easy_baselines') &&
      User.current.allowed_to?(:view_baselines, project)
    },
    after: :tool_panel)

  menu.push(:cashflow, 'javascript:void(0)',
    param: :project_id,
    caption: :'easy_gantt_pro.cashflow.label_cashflow',
    html: { icon: 'icon-summary', style:'display:none'},
    if: proc { |p| p.nil? && EasyGantt.easy_money? },
    after: :tool_panel)

  menu.push(:critical, 'javascript:void(0)',
    param: :project_id,
    caption: :'easy_gantt.button.critical_path',
    html: { icon: 'icon-summary' },
    if: proc { |p| p.present? && EasySetting.value(:easy_gantt_critical_path) != 'disabled' },
    after: :tool_panel)

  menu.push(:add_task, 'javascript:void(0)',
    param: :project_id,
    caption: :label_new,
    html: { icon: 'icon-add' },
    if: proc { |project|
      project.present? &&
      User.current.allowed_to?(:edit_easy_gantt, project) &&
      (User.current.allowed_to?(:add_issues, project) ||
       User.current.allowed_to?(:manage_versions, project))
    },
    after: :tool_panel)

end
