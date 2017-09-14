# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
#run RedmineApp::Application
if true
  map "/spm" do
    run RedmineApp::Application
  end
else
  run RedmineApp::Application
end