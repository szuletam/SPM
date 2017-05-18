#Send reminders about issues that were not updated since X days.
#
#Available options:
#  * days     => number of days since last update (defaults to 7)

#Example:
#  rake redmine:send_whining days=7 RAILS_ENV="production"
#END_DESC

require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require "mailer"

class WhiningMailer < Mailer
  
  attr_accessor :curr_day
  
  def whining_time(users, date)
    user = User.find_by_id(1)
    
	set_language_if_valid Setting.default_language

	@users = users
	
	@date = date
	
	not_in = Setting.exclude_for_whining_mail.join(',')
	
	not_in = not_in.empty? ? '0' : not_in
	
    send_to = User.active.where(["admin = 1 AND id NOT IN (#{not_in})"]).all.map(&:mail)
	
	mail :to => send_to, :subject => l(:mail_subject_users, :count => users.length, :date => date.strftime("%e-%b-%Y"))
  end
  
  def whining_time_user(user, date)
     set_language_if_valid Setting.default_language
	 
	 @date = date
	 
	 mail :to => user.mail, :subject => l(:mail_subject_user, :date => date.strftime("%e-%b-%Y"))
  end
  
  def whining(user, issues, days)	
	set_language_if_valid Setting.default_language
	subject = l(:mail_subject_whining, :count => issues.size, :days => days )

	@issues = issues
    @days = days
    @issues_url = url_for(:controller => 'issues', :action => 'index', :set_filter => 1, :assigned_to_id => user.id, :sort_key => 'updated_on', :sort_order => 'asc')
	mail :to => user.mail, :subject => subject
  end
  
  def whining_admin(admin, issues)      
	  @issues = issues
	  
	  return if @issues.size <= 0 # Empty issue list
	  
      @admin = admin.user
	  
	  mail :to => admin.user.mail, :subject => l(:mail_subject_admin) unless admin.user.nil?
  end
  
  def self.whinings(options={})
  
	days = options[:days] || 7

	roles = Setting.roles_to_notify   
	
	roles = ["0"] if roles.size <= 0

	#@AIG: Validación para cálculo de días
	time = Time.now
	if time.wday == '5'
		@temp = (time + 259200).strftime("%Y-%m-%d")
		if !WhiningMailer.valid_day?(@temp)
			@temp = (time + 345600).strftime("%Y-%m-%d")
		end
		condition = " #{Project.table_name}.status = 1 AND users.status = 1 AND #{IssueStatus.table_name}.is_closed = #{false} AND (#{Issue.table_name}.due_date = '#{Date.tomorrow.to_s}' OR #{Issue.table_name}.due_date = '#{@temp.to_s}') AND #{Issue.table_name}.assigned_to_id IS NOT NULL"
	else
		condition = " #{Project.table_name}.status = 1 AND users.status = 1 AND #{IssueStatus.table_name}.is_closed = #{false} AND #{Issue.table_name}.due_date = '#{Date.tomorrow.to_s}' AND #{Issue.table_name}.assigned_to_id IS NOT NULL"
	end
	
	issues_by_assignee = Issue.joins([:status, :assigned_to, :project, :tracker]).where(condition).group_by(&:assigned_to)

	issues_by_assignee.each do |assignee, issues|
	  
	  next if assignee.nil?

	  #next if Setting.exclude_for_whining_mail.include?(assignee.id.to_s)
		next if assignee.mail_notification.to_s == 'only_assigned'
	  
	  whining(assignee, issues, days).deliver unless assignee.nil? # send email
	  
	end
	
	#admins = Member.joins("join member_roles on member_roles.member_id=members.id AND member_roles.role_id IN(#{roles.join(',')})
	#								   join users on users.id=members.user_id AND users.status = 1").
	#					  group("user_id")
	#admins.each do |admin|

	#issues_no_end = Issue.joins([:status, :assigned_to, :project,:tracker])
	#								.where(["due_date < current_date() AND issue_statuses.is_closed= ? AND projects.status= ? AND projects.id in(SELECT project_id FROM members WHERE user_id= ?)",false, true, admin.user_id])
		#							    .order(:due_date)

		#next if Setting.exclude_for_whining_mail.include?(admin.id.to_s)

		#whining_admin(admin, issues_no_end).deliver # send email


	#end




	 
  end
  

  

  
  def self.week_whinings
    hours_by_week.deliver
  end
  
  
  def self.valid_day?(date)
    return false if Setting.non_working_week_days.include?(date.cwday.to_s)
	return false if Setting.include_holiday.to_i == 0 && Holiday.is_holiday?(date)
	return true
  end
  
  def self.valid_day_week?(date)
	return true if (date.cwday.to_s == '1' && ! Holiday.is_holiday?(date)) || (Setting.include_holiday.to_i == 1 && Holiday.is_holiday?(date) && date.cwday.to_s == '1')
	return true if date.cwday.to_s == '2' && Holiday.is_holiday?((date - 1).to_date)
	return false
  end
  
  def self.date_to_report(date)
	hash_days ={
      1 => 3,
	  2 => 1,
	  3 => 1,
	  4 => 1,
	  5 => 1,
	  6 => 1,
	  7 => 2
	}

	curr_date = (date - hash_days[date.cwday].day).to_date
	while Holiday.is_holiday?(curr_date) || Setting.non_working_week_days.include?(curr_date.cwday.to_s)
	  curr_date = (curr_date - 1.day).to_date
	end
	
	return curr_date
  end
end

namespace :redmine do
  task :send_whining => :environment do
    options = {}
    options[:days] = ENV['days'].to_i if ENV['days']
	if WhiningMailer.valid_day?(Date.today)
	  number = WhiningMailer.whinings(options)
	end	
  end
end

namespace :redmine do
  task :send_whining_week => :environment do
    options = {}
	if WhiningMailer.valid_day_week?(Date.today)
	  number = WhiningMailer.week_whinings
	end
  end
end
