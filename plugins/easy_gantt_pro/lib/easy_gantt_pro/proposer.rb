easy_extensions = Redmine::Plugin.registered_plugins[:easy_extensions]
unless easy_extensions.nil? || Gem::Version.new(easy_extensions.version) < Gem::Version.new('2016.05.00')
  EasyExtensions::ActionProposer.add({ controller: 'easy_gantt', action: 'index' })
end
