Redmine::Plugin.register :easy_gantt_pro do
  name 'PRO Easy Gantt'
  author 'Easy Software Ltd'
  description 'PRO version'
  version '1.8'
  url 'www.easyredmine.com'
  author_url 'www.easysoftware.cz'

  requires_redmine_plugin :easy_gantt, version_or_higher: '1.8'

  if Redmine::Plugin.installed?(:easy_extensions)
    depends_on [:easy_gantt]
  end

end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
