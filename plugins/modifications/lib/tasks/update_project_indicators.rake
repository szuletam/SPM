#Example:
#  rake redmine:update_project_indicators RAILS_ENV="production"
#END_DESC

require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")

class UpdateProjects
  def update_projects
	Project.all.each do |project|
		project.update_column(:project_done_ratio, project.indicator.realized.to_i)
		project.update_column(:project_start_date, project.indicator.mindate)
		project.update_column(:project_due_date, project.indicator.maxdate)
		project.update_column(:spi, IndicatorsLogic::calc_indicators(project)[2])
		project.update_column(:cpi, IndicatorsLogic::calc_indicators(project)[1])
		puts "#{project.name} #{project.spi} #{project.cpi}"
	end
  end
end

namespace :redmine do
  task :update_project_indicators => :environment do    
    task_obj = UpdateProjects.new
	task_obj.update_projects
  end
end
