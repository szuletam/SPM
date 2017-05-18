#Example:
#  rake redmine:set_users_password RAILS_ENV="production"
#END_DESC

require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")

class SetUsersPassword
  def set_users_password
	User.active.all.each do |user|
		user.salt_password(user.login)
		
		puts "#{user.name} #{user.save}"
	end
  end
end

namespace :redmine do
  task :set_users_password => :environment do    
    task_obj = SetUsersPassword.new
	task_obj.set_users_password
  end
end
