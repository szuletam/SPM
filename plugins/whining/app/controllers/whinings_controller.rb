require 'rake/dsl_definition'
require 'rake/task'

class WhiningsController < ApplicationController
  
  before_filter :require_admin
  
  #Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
  RedmineApp::Application.load_tasks # providing your application name is 'sample'

  def sending
	begin
	  Rake::Task["redmine:send_whining"].reenable # in case you're going to invoke the same task second time.
      Rake::Task["redmine:send_whining"].invoke
	rescue; end
	redirect_to settings_path(:tab => :notifications)
  end

end
